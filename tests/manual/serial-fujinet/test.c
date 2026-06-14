/*
* Test serial to Fujinet
*/

#include <conio.h>
#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* BBC OS functions for simple output */
void OSWRCH(unsigned char c);

/* BBC OS read character - direct ROM call at FFE0 */
char (*OSRDCH)(void) = (char (*)(void))0xFFE0;

/* OSBYTE function declarations */
void osbyte(unsigned char op, unsigned char r1, unsigned char r2);

/* Assembly function declarations */
int read_char_with_timeout(unsigned char *ch, unsigned int timeout_centiseconds);
int check_rs423_buffer(void);
int read_rs423_char(unsigned char *ch);

/* OSBYTE constants for serial configuration */
#define osbyte_SERIAL_RECEIVE_RATE    0x07
#define osbyte_SERIAL_TRANSMIT_RATE   0x08
#define osbyte_OUTPUT_STREAMS         0x03
#define osbyte_INPUT_STREAM           0x02
#define osbyte_IN_KEY                 0x81
#define osbyte_FLUSH_BUFFERS          0x15
#define osbyte_READ_ADC               0x80
#define osbyte_REMOVE_CHAR            0x91

/* Baud rates */
#define BAUD_9600                     7
#define BAUD_19200                    8

/* Output stream values */
#define OUTPUT_SCREEN_ONLY            0
#define OUTPUT_SERIAL_ONLY            3

/* Input stream values */
#define INPUT_KEYBOARD_ONLY           0
#define INPUT_SERIAL_ONLY             1

/* Buffer flush values */
#define FLUSH_KEYBOARD_BUFFER         0
#define FLUSH_SERIAL_INPUT_BUFFER     1

/* RS423 buffer values */
#define RS423_INPUT_BUFFER            254  /* ADVAL(-2) */
#define RS423_GET_CHAR                1    /* X=1 for RS423 in OSBYTE 145 */

/* FujiNet device IDs */
#define THE_FUJI                      0x70
#define NETWORK_DEVICE                0x71

#define GET_SSID_LEN                  100
#define GET_HOSTS_LEN                 259  /* AC + 256 payload + checksum */
#define GET_DEVICE_SLOTS_LEN          307  /* AC + 304 payload + checksum (8*38) */
#define MAX_DISPLAY_FILENAME_LEN      36
#define NETWORK_BUFFER_LEN            512

/* Network command bytes */
#define NET_CMD_OPEN                  'O'
#define NET_CMD_CLOSE                 'C'
#define NET_CMD_READ                  'R'
#define NET_CMD_STATUS                'S'
#define NET_CMD_WRITE                 'W'

/* Network modes */
#define NET_MODE_READ                 0x04  /* bit 2 = READ */
#define NET_MODE_WRITE                0x08  /* bit 3 = WRITE */
#define NET_TRANSLATION               0x00  /* always 00 */

// generic buffer for responses
unsigned char response[512];
unsigned char network_buffer[NETWORK_BUFFER_LEN];

// Status response variables
static int status_bytes_waiting = 0;
static int status_connected = 0;
static int status_error_ok = 0;

static void wait_key(const char* prompt) {
    if (prompt) printf("%s", prompt);
    cgetc();
    printf("\n");
}

/* Simple output functions */
void print_char(char c) {
    OSWRCH(c);
}

void print_string(const char* s) {
    while (*s) {
        print_char(*s++);
    }
}

void print_newline(void) {
    print_char(13);  /* CR - Carriage Return (go to beginning of next line) */
    print_char(10);  /* LF - Line Feed (go to beginning of next line) */
}


void wait_for_key(void) {
    print_string("Press any key to continue...");
    print_newline();
    OSRDCH();  /* Direct BBC OS call */
}

void print_hex_byte(unsigned char value) {
    unsigned char high, low;
    high = (value >> 4) & 0x0F;
    low = value & 0x0F;
    
    print_char(high < 10 ? '0' + high : 'A' + high - 10);
    print_char(low < 10 ? '0' + low : 'A' + low - 10);
}

void print_decimal(int value) {
    char buffer[6];
    int i = 0;
    int negative = 0;
    
    if (value < 0) {
        negative = 1;
        value = -value;
    }
    
    if (value == 0) {
        print_char('0');
        return;
    }
    
    while (value > 0) {
        buffer[i++] = '0' + (value % 10);
        value /= 10;
    }
    
    if (negative) {
        print_char('-');
    }
    
    while (i > 0) {
        print_char(buffer[--i]);
    }
}

/* Serial port configuration functions */
void setup_serial_ports(void) {
    /* *fx 7,7 - Set RX to 9600 baud */
    osbyte(osbyte_SERIAL_RECEIVE_RATE, BAUD_19200, 0);
    
    /* *fx 8,7 - Set TX to 9600 baud */
    osbyte(osbyte_SERIAL_TRANSMIT_RATE, BAUD_19200, 0);
    
    /* *fx 3,3 - Output data to serial port (not screen) */
    osbyte(osbyte_OUTPUT_STREAMS, OUTPUT_SERIAL_ONLY, 0);
    
    /* *fx 2,1 - Input from serial port (not keyboard) */
    osbyte(osbyte_INPUT_STREAM, INPUT_SERIAL_ONLY, 0);
    
    /* *fx 21,0 - Flush keyboard buffer */
    osbyte(osbyte_FLUSH_BUFFERS, FLUSH_KEYBOARD_BUFFER, 0);
    
    /* *fx 21,1 - Flush RS423 serial input buffer */
    osbyte(osbyte_FLUSH_BUFFERS, FLUSH_SERIAL_INPUT_BUFFER, 0);

}    

void reset_serial_to_screen(void) {
    /* *fx 3,0 - Reset screen output only */
    osbyte(osbyte_OUTPUT_STREAMS, OUTPUT_SCREEN_ONLY, 0);
    
    /* *fx 2,0 - Reset keyboard input only */
    osbyte(osbyte_INPUT_STREAM, INPUT_KEYBOARD_ONLY, 0);
}

/* FujiNet checksum calculation */
unsigned char rs232_checksum(unsigned char *buf, unsigned short len) {
    unsigned int chk = 0;
    int i;
    
    for (i = 0; i < len; i++) {
        chk = ((chk + buf[i]) >> 8) + ((chk + buf[i]) & 0xff);
    }
    
    return (unsigned char)chk;
}

/* Helper function to check if character is printable */
int is_printable(unsigned char c) {
    return (c >= 32 && c <= 126);
}

/* Hex dump function for received data */
void hex_dump(unsigned char *data, int len) {
    int i, j;
    unsigned char c;
    
    for (i = 0; i < len; i += 8) {
        /* Print address */
        print_hex_byte((i >> 8) & 0xFF);
        print_hex_byte(i & 0xFF);
        print_string(" ");

        /* Print hex bytes */
        for (j = 0; j < 8 && (i + j) < len; j++) {
            print_hex_byte(data[i + j]);
            print_char(' ');
        }
        
        /* Pad with spaces if less than 8 bytes */
        for (j = 8 - j; j > 0; j--) {
            print_string("   ");
        }
        
        print_string("|");
        
        /* Print ASCII representation */
        for (j = 0; j < 8 && (i + j) < len; j++) {
            c = data[i + j];
            if (is_printable(c)) {
                print_char(c);
            } else {
                print_char('.');
            }
        }
        
        print_newline();
    }
}

/* Send data to specific FujiNet device */
void send_data_to_device(unsigned char device_id, unsigned char command, unsigned char arg1, unsigned char arg2, unsigned char arg3, unsigned char arg4) {
    unsigned char packet[7];
    unsigned char checksum;
    
    /* Build packet: device_id, command, arg1, arg2, arg3, arg4, checksum */
    packet[0] = device_id;         /* Device ID */
    packet[1] = command;           /* Command */
    packet[2] = arg1;              /* Arg 1 */
    packet[3] = arg2;              /* Arg 2 */
    packet[4] = arg3;              /* Arg 3 */
    packet[5] = arg4;              /* Arg 4 */
    
    /* Calculate checksum for first 6 bytes */
    checksum = rs232_checksum(packet, 6);
    packet[6] = checksum;
    
    /* Send the packet */
    {
        int i;
        for (i = 0; i < 7; i++) {
            OSWRCH(packet[i]);
        }
    }
}

/* FujiNet reset command */
void fn_reset(void) {
    /* Setup serial ports for 9600 baud */
    setup_serial_ports();
    
    /* Send reset command with 4 zero arguments */
    send_data_to_device(THE_FUJI, 0xFF, 0x00, 0x00, 0x00, 0x00);

    /* Reset everything back to screen/keyboard */
    reset_serial_to_screen();
}

/* Read data from RS423 buffer with waiting */
int read_serial_data(unsigned char *buffer, int length) {
    int i;
    int bytes_received = 0;
    int wait_count = 0;
    const int max_wait = 10000; /* Maximum wait cycles per byte */
    
    for (i = 0; i < length; i++) {
        unsigned char ch = 0;
        int result = 0;
        wait_count = 0;
        
        /* Wait for data to be available in RS423 buffer */
        do {
            if (check_rs423_buffer()) {
                result = read_rs423_char(&ch);
                break;
            }
            wait_count++;
        } while (wait_count < max_wait);
        
        if (wait_count >= max_wait) {
            /* Timeout waiting for data - fill remaining with zeros and break */
            while (i < length) {
                buffer[i++] = 0;
            }
            break;
        }
        
        if (result == 1) {
            buffer[i] = ch;
            bytes_received++;
        } else {
            /* No data available - fill remaining with zeros and break */
            while (i < length) {
                buffer[i++] = 0;
            }
            break;
        }
    }
    
    return bytes_received;
}

/* FujiNet get SSID command */
void fn_get_ssid(void) {
    unsigned char response[GET_SSID_LEN];
    int bytes_received = 0;
    int protocol_valid = 0;
    int checksum_valid = 0;
    unsigned char expected_checksum = 0;
    unsigned char received_checksum = 0;
    unsigned char *payload_ptr;
    
    print_string("fn_get_ssid: Starting...");
    print_newline();
    
    /* Setup serial ports for 9600 baud (both input and output) */
    setup_serial_ports();
    
    /* Send get SSID command with 4 zero arguments */
    send_data_to_device(THE_FUJI, 0xFE, 0x00, 0x00, 0x00, 0x00);
    
    /* Read GET_SSID_LEN bytes from RS423 buffer */
    bytes_received = read_serial_data(response, GET_SSID_LEN);
    
    /* Reset everything back to screen/keyboard */
    reset_serial_to_screen();
    
    /* Validate protocol: ACK + Completed + 97 payload + checksum */
    if (bytes_received >= GET_SSID_LEN) {
        /* Check for ACK ('A') and Completed ('C') */
        if (response[0] == 'A' && response[1] == 'C') {
            protocol_valid = 1;
            
            /* Point to payload (bytes 2-98) */
            payload_ptr = &response[2];
            
            /* Calculate expected checksum for payload */
            expected_checksum = rs232_checksum(payload_ptr, GET_SSID_LEN - 3);
            received_checksum = response[GET_SSID_LEN - 1];
            
            /* Validate checksum */
            if (expected_checksum == received_checksum) {
                checksum_valid = 1;
            }
        }
    }
    
    /* Display the received data */
    print_string("SSID Response (100 bytes):");
    print_newline();
    hex_dump(response, GET_SSID_LEN);
    
    /* Display payload if valid */
    if (protocol_valid && checksum_valid) {
        print_string("Completed successfully");
        print_newline();
    } else {
        print_string("Error in data.");
        print_newline();
    }
}

/* FujiNet get hosts command */
void fn_get_hosts(void) {

    int bytes_received = 0;
    int protocol_valid = 0;
    int checksum_valid = 0;
    unsigned char expected_checksum = 0;
    unsigned char received_checksum = 0;
    unsigned char *payload_ptr;
    int i, j;
    
    print_string("fn_get_hosts: Starting...");
    print_newline();
    
    /* Setup serial ports for 9600 baud (both input and output) */
    setup_serial_ports();
    
    /* Send get hosts command with 4 zero arguments */
    send_data_to_device(THE_FUJI, 0xF4, 0x00, 0x00, 0x00, 0x00);
    
    /* Read GET_HOSTS_LEN bytes from RS423 buffer */
    bytes_received = read_serial_data(response, GET_HOSTS_LEN);
    
    /* Reset everything back to screen/keyboard */
    reset_serial_to_screen();
    
    /* Validate protocol: ACK + Completed + 256 payload + checksum */
    if (bytes_received >= GET_HOSTS_LEN) {
        /* Check for ACK ('A') and Completed ('C') */
        if (response[0] == 'A' && response[1] == 'C') {
            protocol_valid = 1;
            
            /* Point to payload (bytes 2-257) */
            payload_ptr = &response[2];
            
            /* Calculate expected checksum for payload */
            expected_checksum = rs232_checksum(payload_ptr, GET_HOSTS_LEN - 3);
            received_checksum = response[GET_HOSTS_LEN - 1];
            
            /* Validate checksum */
            if (expected_checksum == received_checksum) {
                checksum_valid = 1;
            }
        }
    }
    
    /* Display hosts if valid */
    if (protocol_valid && checksum_valid) {
        print_string("Hosts found:");
        print_newline();
        
        /* Process 8 host slots of 32 bytes each */
        for (i = 0; i < 8; i++) {
            unsigned char *host_ptr = &payload_ptr[i * 32];
            int has_data = 0;
            
            /* Check if this 32-byte slot has any non-zero data */
            for (j = 0; j < 32; j++) {
                if (host_ptr[j] != 0) {
                    has_data = 1;
                    break;
                }
            }
            
            if (has_data) {
                print_string("Host ");
                print_decimal(i + 1);
                print_string(": ");
                
                /* Print the hostname (up to 32 chars, stop at first null) */
                for (j = 0; j < 32; j++) {
                    if (host_ptr[j] == 0) {
                        break;
                    }
                    print_char(host_ptr[j]);
                }
                print_newline();
            }
        }
    } else {
        print_string("Invalid response - cannot display hosts");
        print_newline();
    }
}

/* FujiNet get device slots command */
void fn_get_device_slots(void) {
    int bytes_received = 0;
    int protocol_valid = 0;
    int checksum_valid = 0;
    unsigned char expected_checksum = 0;
    unsigned char received_checksum = 0;
    unsigned char *payload_ptr;
    int i, j;
    
    print_string("fn_get_device_slots: Starting...");
    print_newline();
    
    /* Setup serial ports for 9600 baud (both input and output) */
    setup_serial_ports();
    
    /* Send get device slots command with 4 zero arguments */
    send_data_to_device(THE_FUJI, 0xF2, 0x00, 0x00, 0x00, 0x00);
    
    /* Read GET_DEVICE_SLOTS_LEN bytes from RS423 buffer */
    bytes_received = read_serial_data(response, GET_DEVICE_SLOTS_LEN);
    
    /* Reset everything back to screen/keyboard */
    reset_serial_to_screen();
    
    /* Validate protocol: ACK + Completed + 304 payload + checksum */
    if (bytes_received >= GET_DEVICE_SLOTS_LEN) {
        /* Check for ACK ('A') and Completed ('C') */
        if (response[0] == 'A' && response[1] == 'C') {
            protocol_valid = 1;
            
            /* Point to payload (bytes 2-305) */
            payload_ptr = &response[2];
            
            /* Calculate expected checksum for payload */
            expected_checksum = rs232_checksum(payload_ptr, GET_DEVICE_SLOTS_LEN - 3);
            received_checksum = response[GET_DEVICE_SLOTS_LEN - 1];
            
            /* Validate checksum */
            if (expected_checksum == received_checksum) {
                checksum_valid = 1;
            }
        }
    }
    
    /* Display device slots if valid */
    if (protocol_valid && checksum_valid) {
        print_string("Device Slots:");
        print_newline();
        
        /* Process 8 device slots of 38 bytes each */
        for (i = 0; i < 8; i++) {
            unsigned char *slot_ptr = &payload_ptr[i * 38];
            uint8_t host_slot = slot_ptr[0];
            uint8_t mode = slot_ptr[1];
            char *filename = (char *)&slot_ptr[2];
            int has_filename = 0;
            
            /* Check if filename has any non-zero data */
            for (j = 0; j < MAX_DISPLAY_FILENAME_LEN; j++) {
                if (filename[j] != 0) {
                    has_filename = 1;
                    break;
                }
            }
            
            print_string("Slot ");
            print_decimal(i + 1);
            print_string(": Host=");
            print_decimal(host_slot);
            print_string(", Mode=");
            print_decimal(mode);
            
            if (has_filename) {
                print_string(", File=");
                /* Print the filename (up to 36 chars, stop at first null) */
                for (j = 0; j < MAX_DISPLAY_FILENAME_LEN; j++) {
                    if (filename[j] == 0) {
                        break;
                    }
                    print_char(filename[j]);
                }
            } else {
                print_string(", File=(empty)");
            }
            print_newline();
        }
    } else {
        print_string("Invalid response - cannot display device slots");
        print_newline();
    }
}

/* Send network data to FujiNet */
void send_network_data(const uint8_t *data, int length, uint8_t checksum) {
    int i;
    
    /* Send exactly length bytes of data */
    for (i = 0; i < length; i++) {
        OSWRCH(data[i]);
    }
    
    /* Calculate and send checksum for the data block */
    OSWRCH(checksum);
}

/* FujiNet network test - fetch HTTP data */
void fn_network_test(void) {
    int bytes_received = 0;
    int protocol_valid = 0;
    int checksum_valid = 0;
    unsigned char expected_checksum = 0;
    unsigned char received_checksum = 0;
    const char *url = "n:http://httpbin.org/get";
    unsigned char status_response[10];
    uint8_t checksum;
    int url_len, i;
    char c;

    print_string("fn_network_test: Starting...");
    print_newline();
    print_string("URL: ");
    print_string(url);
    print_newline();
    
    url_len = strlen(url);    
    /* Clear the entire buffer first */
    for (i = 0; i < 256; i++) {
        network_buffer[i] = 0; //i & 0xFF;
    }
    
    /* Copy URL data into buffer */
    for (i = 0; i < url_len && i < 256; i++) {
        network_buffer[i] = url[i];
    }
    network_buffer[i] = 0;
    checksum = rs232_checksum((unsigned char *) network_buffer, 256);

    /* Setup serial ports for 9600 baud (both input and output) */
    setup_serial_ports();
    
    /* Send Open command to Network device */
    send_data_to_device(NETWORK_DEVICE, NET_CMD_OPEN, NET_MODE_READ, NET_TRANSLATION, 0, 0);    
    send_network_data(network_buffer, 256, checksum);

    /* *fx 21,1 - Flush RS423 serial input buffer */
    // osbyte(osbyte_FLUSH_BUFFERS, FLUSH_SERIAL_INPUT_BUFFER, 0);

    // osbyte(15, 0, 0); // clear all the buffers!

    /* Send Status command to get bytes waiting */
    send_data_to_device(NETWORK_DEVICE, NET_CMD_STATUS, 0, 0, 0, 0);
    
    /* Read status response (AACAC + 4 + chksum) */
    {
        int status_bytes = read_serial_data(status_response, 10);
        
        if (status_bytes >= 9 && status_response[0] == 'A' && status_response[1] == 'A' && status_response[2] == 'C') {
            /* Parse status response and store in global variables */
            status_bytes_waiting = status_response[5] | (status_response[6] << 8);
            status_connected = status_response[7];
            status_error_ok = status_response[8];
        } else {
            /* Status command failed, use fallback */
            status_bytes_waiting = 512;
            status_connected = 0;
            status_error_ok = 0;
        }
        
        /* Send Read command with actual bytes waiting */
        send_data_to_device(NETWORK_DEVICE, NET_CMD_READ, status_bytes_waiting & 0xFF, (status_bytes_waiting >> 8) & 0xFF, 0, 0);
        
        /* Read response from RS423 buffer, skip the ACK and Complete bytes */
        read_serial_data(network_buffer, 2);
        bytes_received = read_serial_data(network_buffer, status_bytes_waiting);
        read_serial_data(&c, 1);
    }
    
    /* Reset everything back to screen/keyboard */
    reset_serial_to_screen();
   
    wait_key("press a key...");
    /* Now we can safely print debug messages to screen */
    hex_dump(status_response, 10);

    print_string("Status: bytes_waiting=");
    print_decimal(status_bytes_waiting);
    print_string(", connected=");
    print_decimal(status_connected);
    print_string(", error_ok=");
    print_decimal(status_error_ok);
    print_newline();
    print_string("Sent Read command");
    print_newline();
    wait_key("press a key...");
    print_string("Read response");
    print_newline();
    
    /* Display results */
    print_string("Bytes received: ");
    print_decimal(bytes_received);
    print_newline();
    
    if (bytes_received > 0) {
        print_string("HTTP Response (first 100 bytes):");
        print_newline();
        hex_dump(network_buffer, (bytes_received < 100) ? bytes_received : 100);
        
        if (bytes_received > 100) {
            print_string("... (truncated)");
            print_newline();
        }
    } else {
        print_string("No data received");
        print_newline();
    }
    
    /* Send Close command */
    setup_serial_ports();
    send_data_to_device(NETWORK_DEVICE, NET_CMD_CLOSE, 0, 0, 0, 0);
    reset_serial_to_screen();
    print_string("Sent Close command");
}

void show_menu(void) {
    print_string("=== FujiNet Serial Test Menu ===");
    print_newline();
    print_string("1. Reset FujiNet");
    print_newline();
    print_string("2. Get SSID");
    print_newline();
    print_string("3. Get Hosts");
    print_newline();
    print_string("4. Get Device Slots");
    print_newline();
    print_string("5. Network Test (HTTP)");
    print_newline();
    print_string("6. Exit");
    print_newline();
    print_string("Enter choice (1-6): ");
}

int main(void) {
    char choice;
    
    print_string("FujiNet Serial Test Starting...");
    print_newline();
    print_newline();
    
    while (1) {
        show_menu();
        
        /* Read a single character from keyboard */
        choice = OSRDCH();
        
        print_newline();
        print_newline();
        
        switch (choice) {
            case '1':
                print_string("=== Testing Reset Command ===");
                print_newline();
                fn_reset();
                break;
                
            case '2':
                print_string("=== Testing Get SSID Command ===");
                print_newline();
                fn_get_ssid();
                break;
                
            case '3':
                print_string("=== Testing Get Hosts Command ===");
                print_newline();
                fn_get_hosts();
                break;
                
            case '4':
                print_string("=== Testing Get Device Slots Command ===");
                print_newline();
                fn_get_device_slots();
                break;
                
            case '5':
                print_string("=== Testing Network HTTP Command ===");
                print_newline();
                fn_network_test();
                break;
                
            case '6':
                print_string("Exiting...");
                print_newline();
                return 0;
                
            default:
                print_string("Invalid choice. Please enter 1-6.");
                print_newline();
                break;
        }
        
        print_newline();
        print_newline();
        wait_key("Press a key...");
        print_newline();
    }
}
