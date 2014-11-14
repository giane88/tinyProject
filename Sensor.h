#ifndef SENSOR_H
#define SENSOR_H

enum {
  AM_RADIO = 6,
  SAMPLING_FREQ = 5120,
  SINK_FREQ = 10240,
  DELAY_BASE = 1024,
  N_MOTES = 10,
  N_SAMPLE = 6
};

typedef nx_struct SensorMsg {
    nx_uint16_t nodeid;
    nx_uint32_t avg;
} SensorMsg;

typedef nx_struct RequestMsg {
    nx_uint16_t requestid;
} RequestMsg;

#endif;
