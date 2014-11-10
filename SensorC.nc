#include <Sensor.h>

module SensorC
{
    uses interface Boot;
    uses interface Timer<TMilli> as Timer0;
    uses interface Read<uint16_t>;
    uses interface Packet;
    uses interface AMPacket;
    uses interface Receive;
    uses interface SplitControl as AMControl;
}
implementation
{

    uint16_t temp1;
    uint16_t temp2;
    uint16_t temp3;
    uint16_t temp4;
    uint16_t temp5;
    uint16_t temp6;
    bool busy = FALSE;
    message_t pkt;

    event void Boot.booted() {
        dbg("default", "%s | Node %d started\n", sim_time_string(), TOS_NODE_ID);
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call Timer0.startPeriodic(SAMPLING_FREQ);
        } else {
            AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err) {}

    event void Timer.fired()
    {
        call Read.read();
    }

    event void Read.readDone(error_t result, uint16_data)
    {
        if(result == SUCCESS) {
            temp1 = temp2;
            temp2 = temp3;
            temp3 = temp4;
            temp4 = temp5;
            temp5 = temp6;
            temp6 = data;
        }
    }

    task void replayMsg(am_addr_t source) 
    {
        uint16_t tempavg;
        tempavg = (temp1+temp2+temp3+temp4+temp5+temp6)/6;
        //Invio del messaggio.
        if(!busy) {
            SensorMsg* senpkt = (SensorMsg*)(call Packet.getPayload(&pkt, sizeof(SensorMsg)));
            if(senpkt == NULL) return;
            senpkt->nodeid = TOS_NODE_ID;
            senpkt->avg = tempavg;
            if( call AMSend.send(source, &pkt, sizeof(SensorMsg)) == SUCCESS) {
                busy = TRUE;
                dbg("default", "%s | Sent avg temp = %d from %d",sim_time_string(), tempavg, TOS_NODE_ID);
            }
        }
    }

    event void AMSend.sendDone(message_t* msg, error_t err) {
        if (&pkt == msg) busy = FALSE;
    }


    event message_t* receive.receive(message_t* msg, void payload, uint8_t len) {
        am_addr_t sourceAddr;
        if (len == sizeof(SensorMsg)) {
            SensorMsg* senpkt = (SensorMsg*) payload;
            //Confronto con comando per l'invio del messaggio di richiesta della temperatura media
            sourceAddr = call AMPacket.source(msg);
            post replayMsg(sourceAddr);
            dbg("default","%s | Node %d: Recived command from %d, sending the avg temperature", sim_time_string(), TOS_NODE_ID, sourceAddr);
        }
        return msg;
    }
}
