namespace IRCBot {
	
	class Bot : BotBase {
		
		public override void handleCommand(string strFrom, string strMessage){
			string[] arrData = strMessage.split(" ");
			string strCommand = arrData[0].substring(1);
			Logger.Log("Received command: " + strCommand);
			switch(strCommand.up()){
				case "JOIN":
					this.joinChannel(arrData[1]);
				break;
				case "NICK":
					this.changeNick(arrData[1]);
				break;
				case "SAY":
					string strReply = this.buildString(arrData, 1, true);
					this.sendMessage(strFrom, strReply);
				break;
			}
			this.lastCommandChannel = strFrom;
		}
		
		public void run(){
			this.netConnect(this.Config["Address"], this.Config["Port"]);
			while(true){
				if(this.Connection.is_closed() == true){
					break;
				}
				this.recvData();
			}
		}
		
	}
	
}
