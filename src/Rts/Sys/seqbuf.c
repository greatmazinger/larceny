/* Copyright 2007 Felix S Klock II.
 *
 * $Id$
 * 
 * Sequential store buffer implementation.
 * 
 */

#define GC_INTERNAL

#include "larceny.h"
#include "seqbuf_t.h"
#include "gclib.h"

typedef struct seqbuf_data seqbuf_data_t;

struct seqbuf_data {
  seqbuf_processor ep;
  void* sp_data;
};

#define DATA(ssb)               ((seqbuf_data_t*)(ssb->data))

seqbuf_t *
create_seqbuf( int num_entries, /* Number of entries in SSB */
	       word **bot_loc,  /* Location of pointer to start of SSB */
	       word **top_loc,  /* Location of pointer to next free of SSB*/
	       word **lim_loc,  /* Location of pointer past end of SSB */
	       seqbuf_processor processor,
	       void *sp_data )
{
  seqbuf_t *ssb;
  seqbuf_data_t *ssb_data;
  word *buf;

  if (num_entries == 0) num_entries = DEFAULT_SSB_SIZE;
  
  annoyingmsg( "Allocated seqbuf entries=%d", num_entries );

  ssb = (seqbuf_t*)must_malloc( sizeof( seqbuf_t ) );
  ssb_data = (seqbuf_data_t*)must_malloc( sizeof( seqbuf_data_t ) );

  ssb->bot = bot_loc;
  ssb->top = top_loc;
  ssb->lim = lim_loc;
  ssb->data = ssb_data;

  while (1) {
    buf = gclib_alloc_rts( num_entries * sizeof(word), MB_REMSET );
    if (buf != 0)
      break;
    memfail( MF_RTS, "Can't allocate sequential store buffer." );
  }
  *ssb->bot = *ssb->top = buf;
  *ssb->lim = buf + num_entries;

  DATA(ssb)->ep = processor;
  DATA(ssb)->sp_data = sp_data;

  return ssb;
}

void seqbuf_swap_in_ssb( seqbuf_t *ssb, 
                         word **bot_loc, word **top_loc, word **lim_loc )
{
  *bot_loc = *ssb->bot;
  *top_loc = *ssb->top;
  *lim_loc = *ssb->lim;
  ssb->bot = bot_loc;
  ssb->top = top_loc;
  ssb->lim = lim_loc;
}

void* seqbuf_set_sp_data( seqbuf_t *ssb, void *sp_data )
{
  void *old_sp_data;
  old_sp_data = DATA(ssb)->sp_data;
  DATA(ssb)->sp_data = sp_data;
  return old_sp_data;
}

int process_seqbuf( gc_t *gc, seqbuf_t *ssb ) 
{
  int retval;
  
  void *sp_data = DATA(ssb)->sp_data;
  retval = DATA(ssb)->ep( gc, *ssb->bot, *ssb->top, sp_data );
  *ssb->top = *ssb->bot;
  return retval;
}

bool seqbuf_clearp( seqbuf_t *ssb ) 
{
  return (*ssb->top == *ssb->bot);
}
