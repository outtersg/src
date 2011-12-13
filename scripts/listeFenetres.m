#import <Cocoa/Cocoa.h>

int main(int argc, char ** argv)
{
	AXUIElementRef app = AXUIElementCreateApplication(711);
	NSArray * fs;
	NSString * nom;
	printf("%x\n", app);
	AXUIElementCopyAttributeValues(app, kAXWindowsAttribute, 0, 99999, &fs);
	printf("%d\n", [fs count]);
	for(id f in fs)
	{
		AXUIElementCopyAttributeValue(f, kAXTitleAttribute, &nom);
		printf("%s\n", [nom cString]);
	}
}
