#include "Sensor.h"

configuration SensorAppC
{
}
implementation
{
	components SensorC;
	components MainC;
	components new TimerMilliC() as Timer0;
	components new DemoSensorC() as Sensor;
    components ActiveMessageC;
    components new AMSenderC(AM_RADIO);
    components new AMReceiverC(AM_RADIO);

	SensorC.Boot -> MainC;
    SensorC.Timer0 -> Timer0;
    SensorC.Read -> Sensor;
    SensorC.Packet -> AMSenderC;
    SensorC.AMPacket -> AMSenderC;
    SensorC.AMSend -> AMSenderC;
    SensorC.Receive -> AMReceiverC;
    SensorC.AMControl -> ActiveMessageC;
}
	
