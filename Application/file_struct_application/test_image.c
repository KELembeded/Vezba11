#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "test.h"

int main(void)
{
  FILE* fp;
  int x,y;
  int ret = 0;
  
  
  
  for(y=0; y<144; y++)
    {
      for(x=0; x<256; x++)
	{
	  fp = fopen("/dev/vga", "w");
	  if(fp == NULL)
	    {
	      printf("Cannot open /dev/vga for write\n");
	      return -1;
	    }
	  ret = fprintf(fp,"%d,%d,%#04x\n",x,y,image[y*256+x]);      
	  if(fclose(fp) == EOF)
	    {
	      printf("Cannot close /dev/vga\n");
	      return -1;
	    }
	}
    }
  
  return 0;
}

