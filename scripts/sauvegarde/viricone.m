/*
ATTENTION: pas suffisant. Il traîne encore après ça des attributs qui
perturbent rsync. Utiliser tqvs.
cc -o /tmp/viricone -framework Foundation -framework Carbon -framework AppKit viricone.m IconFamily.m NSString+CarbonFSRefCreation.m
*/

#import "IconFamily.h"

int main(int argc, char ** argv)
{
	id marigaud = [[NSAutoreleasePool alloc] init];
	while(*++argv)
		[IconFamily removeCustomIconFromFile:[NSString stringWithCString:*argv]];
	[marigaud release];
	return 0;
}
