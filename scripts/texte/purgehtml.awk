# Pour virer toutes les mentions de police etc. qui traînent dans les <blockquote> quand on répond sous RoundCube à quelqu'un qui a composé sous Outlook.

{
	gsub(/<!--[^>]* ignored -->/, "");
	gsub(/(font-size|mso-fareast-language|font-family):[^;"]*;?/, "");
	gsub(/ style=" *"/, "");
	while(gsub(/<span>([^<]+|<br *\/*>)*<\/span>/, "<&>"))
		gsub(/<<span>|<\/span>>/, "");
	print;
}
