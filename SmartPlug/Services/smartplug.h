//
//  smartplug.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#ifndef smartplug_h
#define smartplug_h

/*
 * SmartPlug definitions
 */
#define MAX_DATA_SIZE           494
#define MAX_ENC_DATA_SIZE       468
#define CMD_HEADER_CODE         0x534D5254
#define REPLY_HEADER_CODE       0x534D5253
#define ENCMSG_SIZE             488


#define NETWORK_CHANGE_BROADCAST_ACTION     @"android.net.conn.CONNECTIVITY_CHANGE"
#define SCAN_FINISHED_BROADCAST_ACTION      @"com.jiee.smartplug.utils.SCAN_FINISHED"
#define DEVICE_FOUND_BROADCAST_ACTION       @"com.jiee.smartplug.utils.DEVICE_FOUND"
#define SPLASH_SCREEN_TIME                  2000    // 2 seconds
#define MAIN_SCAN_TIME                      15000   // 15 seconds
#define JMDNS_CLOSE_TIME                    6000    // 6 seconds
#define TAB_DIMENS                          80      // the size of the tabs in dp
#define SC_RUNTIME                          60000   // one minute
#define SC_PROGRESSBAR_INTERVAL             1000    // one second
#define SC_MDNS_INTERVAL                    10000   // 10 seconds
#define ZERO_PADDING_16                     @"0000000000000000"


/*
 * SmartPlug command codes
 */

// Unencrypted command type
typedef enum {
    DEVICE_QUERY = 1,
    DEVICE_ACTIVATION,
    WIFI_SCAN,
    STOP_WIFI_SCAN,
    SET_WIFI_AP,
} UNENCRYPTED_COMMAND_TYPE;

// Encrypted command type
typedef enum {
    WIFI_SCAN = 3,
    STOP_WIFI_SCAN,
    SET_WIFI_AP,
    DEVICE_CAPABILITY,
    GET_DEVICE_STATUS,
    SET_DEVICE_STATUS,
    SET_DEVICE_TIMERS,
    GET_DEVICE_TIMERS,
    DELAY_TIMER,
    READ_ADVANCED_DEVICE_SERVICE_SETTINGS,
    BROADCAST_STATUS_CHANGE = 0x1000,
    BROADCAST_SETTINGS_CHANGE = 0x1001,
    BROADCAST_DEVICE_REBOOTED = 0x1002,
    FACTORY_RESET_DEVICE = 0xFFFF
} ENCRYPTED_COMMAND_TYPE;

/*
 * SmartPlug packet definitions
 */

#pragma pack(push)
#pragma pack(1)

typedef struct {
    unsigned int header;    // Must be CMD_HEADER_CODE
    unsigned int msgid;
    unsigned int seq;
    unsigned short size;    // Length of data+command in bytes
    unsigned short command;
    unsigned char data[MAX_DATA_SIZE-2];
    unsigned int crc;       // CRC32 checksum for whole packet, minus header
} UnencFirstCmdPacket;

typedef struct {
    unsigned int header;    // Must be CMD_HEADER_CODE
    unsigned int msgid;
    unsigned int seq;
    unsigned short size;    // Length of data in bytes
    unsigned char data[MAX_DATA_SIZE];
    unsigned int crc;
} UnencCmdPacket;

typedef struct {
    unsigned int header;    // Must be REPLY_HEADER_CODE
    unsigned int msgid;
    unsigned int seq;
    unsigned short size;    // Length of data+response in bytes
    unsigned short response;
    unsigned char data[MAX_DATA_SIZE-2];
    unsigned int crc;
} UnencFirstReplyPacket;

typedef struct {
    unsigned int header;    // Must be REPLY_HEADER_CODE
    unsigned int msgid;
    unsigned int seq;
    unsigned short size;    // Length of data in bytes
    unsigned char data[MAX_DATA_SIZE];
    unsigned int crc;
} UnencReplyPacket;

typedef struct {
    unsigned char deviceid[8];
    unsigned char iv[16];
    unsigned char encmsg[ENCMSG_SIZE];
} EncPacket;

typedef struct {
    unsigned int msgid;
    unsigned int seq;
    unsigned short reserved;
    unsigned int time;
    unsigned short size;
    unsigned short command;
    unsigned char data[MAX_ENC_DATA_SIZE-2];
    unsigned int crc;
} EncFirstCmdPacket;

typedef struct {
    unsigned int msgid;
    unsigned int seq;
    unsigned short reserved;
    unsigned int time;
    unsigned short size;
    unsigned char data[MAX_ENC_DATA_SIZE];
    unsigned int crc;
} EncCmdPacket;

typedef struct {
    unsigned int msgid;
    unsigned int seq;
    unsigned short reserved;
    unsigned int time;
    unsigned short size;
    unsigned short response;
    unsigned char data[MAX_ENC_DATA_SIZE-2];
    unsigned int crc;
} EncFirstReplyPacket;

typedef struct {
    unsigned int msgid;
    unsigned int seq;
    unsigned short reserved;
    unsigned int time;
    unsigned short size;
    unsigned char data[MAX_ENC_DATA_SIZE];
    unsigned int crc;
} EncReplyPacket;

#pragma pack(pop)

#endif /* smartplug_h */
