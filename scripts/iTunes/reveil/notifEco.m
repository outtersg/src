#include <Cocoa/Cocoa.h>

int main(int argc, char ** argv)
{
	id vivier = [[NSAutoreleasePool alloc] init];
	id con = [[NSConnection connectionWithRegisteredName:@"com.apple.ScreenSaverDaemon" host:nil] retain];
	id racine = [[con rootProxy] retain];
	[racine restartForUser:nil];
	[racine release];
	[con release];
	[vivier release];
	return 0;
}
