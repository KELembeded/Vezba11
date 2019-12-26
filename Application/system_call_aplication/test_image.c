#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include "test.h"

int main(void)
{
  int fp;
  int x,y;
  char niz[20];

  fp = open("/dev/vga", O_WRONLY);
  if (fp < 0)
    {	    
      printf("error opening file\n");
      return 0;
    }
  for(y=0; y<144; y++)
  {        
      for(x=0; x<256; x++)	
      {
	sprintf(niz, "%d,%d,%d", x,y,image[y*256+x]);
	write(fp,niz, strlen(niz));
      }
  }
  
  if (close(fp) != 0)
    {
      printf("error closing file\n");
      return 0;
    }
  
  return 0;
}

