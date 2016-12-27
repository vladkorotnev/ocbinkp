//
//  ARBinkStructs.h
//  ocbinkp
//
//  Created by Akasaka Ryuunosuke on 26/12/16.
//  Copyright (c) 2016 Akasaka Ryuunosuke. All rights reserved.
//

#ifndef ocbinkp_ARBinkStructs_h
#define ocbinkp_ARBinkStructs_h

typedef enum : unsigned char {
    M_NUL   = 0,
    M_ADR   = 1,
    M_PWD   = 2,
    M_FILE  = 3,
    M_OK    = 4,
    M_EOB   = 5,
    M_GOT   = 6,
    M_ERR   = 7,
    M_BSY   = 8,
    M_GET   = 9,
    M_SKIP  = 10
} ARBinkCommand;

typedef enum : unsigned char {
    ARBinkFrameTypeData,
    ARBinkFrameTypeCommand,
} ARBinkFrameType;

struct ARBinkFrame {
    ARBinkFrameType type;
    uint16_t header;
    uint8_t data[32767];
    uint16_t datalen;
    ARBinkCommand command;
    bool isOut;
};
typedef struct ARBinkFrame ARBinkFrame;



#endif
