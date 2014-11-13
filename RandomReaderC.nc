generic module RandomReader()
{
  provides interface Read<uint16_t>;
  uses interface Random;
}
implementation
{
  task void readTask() {
    signal Read.readDone(SUCCESS, call Random.rand16() % 100);
  }

  command error_t Read.read() {
    post readTask();
    return SUCCESS;
  }
}
	
