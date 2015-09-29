/*
 *  spiral.c
 *  GameBase
 *
 *  Created by blinkenlichten on 11.10.09.
 *  Copyright 2009 wysiwyg* software design gmbh.
 *
 */

#include "spiral.h"

#include <stdio.h>
#include <math.h>
#include <string.h>


#define PI 3.141592653589793f
#define SQRT2 1.414213562373095ffloat


void printLookUp (unsigned int* table, int extent) {
	char lineBuffer [extent + 1];
	lineBuffer [extent] = 0;
	for (int y = 0; y < extent; y++) {
		for (int x = 0; x < extent; x++)
			lineBuffer [x] = table [x] ? '#' : '-';
		
		printf ("%s\n", lineBuffer);
		table += extent;
		
	}
	
}

int spiral (int extent, unsigned int* sequenceOut) {
	int bufferSize = extent * extent;
	
	unsigned int spiralTable [bufferSize];
	bzero (spiralTable, bufferSize * sizeof (unsigned int));
	
	float offset = (extent - 1) / 2;
	float upperU = (float) extent * 6.2f;
	
	int cursor = 0;
	for (float u = 0; u < upperU; u += .1 / 2) {
		float radius = u / PI / 4.f;
		int x = (int) roundf (offset + radius * cosf (u));
		int y = (int) roundf (offset + radius * sinf (u));
		
		if (x < 0 || x >= extent ||
			y < 0 || y >= extent)
			continue;
		
		int address = x + y * extent;
		if (spiralTable [address])
			continue;
		
		spiralTable [address] = 1;
		// printf ("new point %i; %i\n", x, y);

		sequenceOut [cursor++] = address;
		
	}
	// printLookUp (spiralTable, extent);
		
	return cursor;
	
}
