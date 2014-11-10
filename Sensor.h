#ifndef SENSOR_H
#define SENSOR_H

enum {
    AM_RADIO = 6;
    SAMPLING_FREQ = 5000;
};

typedef nx_struct SensorMsg {
    nx_uint16_t nodeid;
    nx_uint16_t avg;
} SensorMsg;

#endif;
