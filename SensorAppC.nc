#include "Sensor.h"

configuration SensorAppC
{
}
implementation
{
    components SensorC;
    components MainC;
    components new TimerMilliC() as SinkTimer;
    components new TimerMilliC() as SensorTimer;
    components new TimerMilliC() as DelayTimer;
    components new RandomSensorC() as RSensor;
    components ActiveMessageC;
    components new AMSenderC(AM_RADIO);
    components new AMReceiverC(AM_RADIO);
    components RandomC;

    SensorC.Boot -> MainC;
    SensorC.SampleTimer -> SensorTimer;
    SensorC.SinkTimer -> SinkTimer;
    SensorC.DelayTimer -> DelayTimer;
    SensorC.Read -> RSensor;
    SensorC.Packet -> AMSenderC;
    SensorC.AMPacket -> AMSenderC;
    SensorC.AMSend -> AMSenderC;
    SensorC.Receive -> AMReceiverC;
    SensorC.AMControl -> ActiveMessageC;
    SensorC.Random -> RandomC;
}
	
