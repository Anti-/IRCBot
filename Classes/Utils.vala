namespace IRCBot {
	
	class Utils : GLib.Object {

		public static string getBetween(string strContent, string strStart, string strEnd){
			string[] arrFirst = strContent.split(strStart);
			if(arrFirst[1] == null) return "";
			string[] arrSecond = arrFirst[1].split(strEnd);
			return arrSecond[0];
		}
		
		public static string fetch(string strPage){
			var session = new Soup.SessionAsync();
			var message = new Soup.Message("GET", strPage);
			session.send_message(message);
			return (string)message.response_body.data;
		}
	}
}
