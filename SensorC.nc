#include <Sensor.h>

module SensorC
{
    uses interface Boot;
    uses interface Timer<TMilli> as SampleTimer;
    uses interface Timer<TMilli> as SinkTimer;
    uses interface Timer<TMilli> as DelayTimer;
    uses interface Read<uint16_t>;
    uses interface Packet;
    uses interface AMPacket;
    uses interface Receive;
    uses interface SplitControl as AMControl;
    uses interface Random;
}
implementation
{
    //Shared Variable
    bool busy = FALSE;
    message_t pkt;
    am_addr_t sourceAddr;
    //Sensor Variable
    uint16_t temp[N_SAMPLE];
    uint8_t index = 0;
    //Sink Variable
    uint16_t nodeid;
    uint16_t reqid = 0;



    /*Metodi condivisi*/
    event void Boot.booted() {
        dbg("default", "%s | [Node %d] starting...\n", sim_time_string(), TOS_NODE_ID);
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            if (TOS_NODE_ID == 0) {
                call SinkTimer.startPeriodic(SINK_FREQ);
            } else {
                call SampleTimer.startPeriodic(SAMPLING_FREQ);
            }
        } else {
            dbgerror("error", "%s | [Node %d] start fail recall AMControl.start()\n");
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err) {}
    
    event void AMSend.sendDone(message_t* msg, error_t err) {
        if (err == SUCCESS) {        
            if (&pkt == msg) busy = FALSE;
        } else {
            dbgerror("error", "%s | [Node %d] error in sendDone\n", sim_time_string(), TOS_NODE_ID);
        }
    }
    
    event message_t* Receive.receive(message_t* msg, void payload, uint8_t len) {
        am_addr_t destAddr;
        if (len == sizeof(RequestMsg)) {
            RequestMsg* reqpkt = (RequestMsg*) payload;
            sourceAddr = call AMPacket.source(msg);
            destAddr = call AMPacket.destination(msg);
            if(destAddr == TOS_BCAST_ADDR){
	        call DelayTimer.startOneShot(call Random.rand16() % DELAY_BASE);
            } else {
                post replayMsg(sourceAddr);
                dbg("default","%s | Node %d: Recived command from %d id = %d, sending the avg temperature", sim_time_string(), TOS_NODE_ID, sourceAddr,reqpkt->requestid);
            }
        }
	if (len == sizeof(SensorMsg)) {
	  SensorMsg* senmsg = (SensorMsg*) payload;
	  sourceAddr = call AMPacket.source(msg);
	  dbg("default", "%s | [Sink] Receive temperature from %d the value is %f", sim_time_string(), senmsg->nodeid, senmsg->avg);
        return msg;
    }
     
    /*Metodi utilizzati dai sensori*/
    event void SampleTimer.fired()
    {
        call Read.read();
    }

    event void Read.readDone(error_t result, uint16_data)
    {
        if(result == SUCCESS) {
            temp[index] = data;
            if(index >= (N_SAMPLE - 1)) {
                index == 0;
            } else {
                index++;
            }                
        }
    }
    
    float calcAvg() {
      float sum;
      uint8_t i;
      
      for (i = 0; i < N_SAMPLE; i++) {
	sum += temp[i];
      }
      return (sum/N_SAMPLE);
    }      
    
    task void replayMsg(am_addr_t source) 
    {
        uint32_t tempavg;
        tempavg = calcAvg();
        //Invio del messaggio.
        if(!busy) {
            SensorMsg* senpkt = (SensorMsg*)(call Packet.getPayload(&pkt, sizeof(SensorMsg)));
            if(senpkt == NULL) return;
            senpkt->nodeid = TOS_NODE_ID;
            senpkt->avg = tempavg;
            if( call AMSend.send(source, &pkt, sizeof(SensorMsg)) == SUCCESS) {
                busy = TRUE;
                dbg("default", "%s | Sent avg temp = %f from %d",sim_time_string(), tempavg, TOS_NODE_ID);
            }
        }
    }

    event DelayTimer.fired() {
        post replayMsg(sourceAddr);
    }

    /* Metodi utilizzati dal Sink*/
    bool broadcast() {
        return (call Random.rand16() % 2);
    }
    
    task void sendRequest() {
        if (!busy) {
            RequestMsg* reqpkt = (RequestMsg*)(call Packet.getPayload((&pkt), sizeof(RequestMsg)));
            if(reqpkt == NULL) return;
            reqid++;
            reqpkt -> requestid = reqid;
            if (broadcast()) {
                dbg("default", "%s | [SINK] sending request message to BROADCAST",sim_time_string());
                if (call AMSend.send(AM_BROADCAST_ADD, &pkt, sizeof(RequestMsg)) == SUCCESS) {
                    busy == TRUE;
                }
            } else {
	        nodeid = ((call Random.rand16() % (N_MOTES -1)) + 1);
                dbg("default", "%s | [SINK] sending request message to %d",sim_time_string(),nodeid);
                if (call AMSend.send(nodeid, &pkt, sizeof(RequestMsg)) == SUCCESS) {
                    busy == TRUE;
                }
            }
        }
    }
    
    event void SinkTimer.fired() {
        post sendRequest();
    }

   
}
