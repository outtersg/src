// cc -o animer animer.cpp -lstdc++ -lmagick -lMagick++ -lgcc_s.1
#include <Magick++.h>
#include <list>

using namespace std;
using namespace Magick;

int main(int argc, char ** argv)
{
	list<Image> images;
	list<Image> temp;
	char * sortie = "animation.gif";
	int temps = 50;
	
	while(*++argv)
	{
		if(strcmp(*argv, "-o") == 0 && argv[1])
		{
			sortie = *++argv;
			continue;
		}
		if(strcmp(*argv, "-d") == 0 && argv[1])
		{
			temps = atoi(*++argv);
			continue;
		}
		readImages(&temp, *argv);
		for_each(temp.begin(), temp.end(), animationDelayImage(temps));
		images.merge(temp);
	}
	for_each(images.begin(), images.end(), animationIterationsImage(0));
	writeImages(images.begin(), images.end(), sortie);
	return 0;
}
