/**CFile***********************************************************************

  FileName    [nimstr.c]

  Author      [Freddy Y.C. Mang]

  Permission is hereby granted, without written agreement and without license
  or royalty fees, to use, copy, modify, and distribute this software and its
  documentation for any purpose, provided that the above copyright notice and
  the following two paragraphs appear in all copies of this software.

******************************************************************************/

/*
Modifications performed by Glenn C. Rhoads (copyright June 1, 2004).

(1) Corrected the functions "check_capturable" and "node_is_capturable"
Previous version said "*-*-*" is loony when it is in fact capturable.
(2) Implemented an entirely new hashing scheme which is faster for
"large" strings-and-coins graphs.
(3) The function "Reflect" was incorrect and the function "Rotate"
was inefficient.  But the program runs faster without this "refinement"
and hence was removed.
(4) The function "Decompose" had a minor glitch that slowed down the
program significantly.
(5) The input and initialization code was greatly streamlined (there is
now only about 1/2 as much code for this part).
(6) Modified/rewrote the original C program in a good C++ style
(e.g. uses constants and inline functions instead of #defines,
uses classes for "nodes" and for the hash table, etc.
(7) Various other improvements to the coding style resulting in a
more elegant and easier to understand implementation.

(8) Program now checks for input with too many potential strings and
warns when a nim-value of a sub-position is too big. (May 22, 2007)
(9) A couple of minor speedups -- (A)avoid intermediate flushing of output;
    (B) Avoid multiple 1-step follower calls for internal strings
   (June 15, 2007)

Permission granted to use this software for non-commercial purposes
provided that this comment block appears in all copies of the software.
All other rights retained.
*/

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include "nim.h"

using namespace std;


int main( int argc, char** argv )
   {
   if (argc != 2)
      {
      cerr << "usage: " << argv[0] << " <filename>" << endl;
      exit(1);
      }

   ifstream infile( argv[1] );

   if (! infile ) {
      cerr << "ERROR: can't open input file" << endl;
      }

   new NimString( infile );
   }



NimString::NimString( ifstream &infile )
   {
   htable = new HT();

   WallNode = new Node();
   WallNode->ground = true;
  
   read_input( infile );
   infile.close();

   is_rectangular();
   make_neighbors();
   make_bitmasks();
   print_game();

   int nimber = find_value( conf );

   if (nimber == LOONY)
      cout << "nimber = L\n\n";
   else 
      cout << "nimber = " << nimber << "\n\n";

   cout << "The 1-step followers are:\n\n";
   print_followers();

   }


void NimString::read_input( ifstream &infile )
   {
   last_row = -1; last_col = -1;

   char c;
   for (int i = 0; ! infile.eof(); i++)
      for (int j = 0; infile.get( c ), ! infile.eof(); j++)
         {
         if (c == '\n')
            {
            line[i][j] = '\0';
            break;
            }

         line[i][j] = c;

         if (c == COIN)
            {
            if (last_col < j) last_col = j;
            if (last_row < i) last_row = i;
            }
         }

   cols = (last_col-1) / 2 + 1;
   rows = (last_row-1) / 2 + 1;
   }


void NimString::is_rectangular()
   {
   int i, j;

   // check for internal walls
   // ------------------------
   for (i = 1; i <= last_row; i += 2)
      for (j = 2; j <= last_col; j += 2)
         {
         char tmp = line[i][j];
         if (tmp == NORTHWALL || tmp == SOUTHWALL || tmp == EASTWALL ||
             tmp == WESTWALL)
            {
            cerr << "Error: internal wall at (" << i << "," << j << ")."
                 << endl;
            exit(1);
            }
         }

   for (i = 2; i <= last_row; i += 2)
      for (j = 1; j <= last_col; j += 2)
         {
         char tmp = line[i][j];
         if (tmp == NORTHWALL || tmp == SOUTHWALL || tmp == EASTWALL ||
             tmp == WESTWALL) 
            {
            cerr << "Error: internal wall at (" << i << "," << j << ")."
                 << endl;
            exit(1);
            }
         }

   // make sure all non-wall strings are attached to a coin
   // -----------------------------------------------------
   for (i = 1; i <= last_row; i += 2)
      for (j = 2; j <= last_col; j += 2)

         if (line[i][j] == HSTRING) 
            if ((j == 0) || (line[i][j-1] != COIN) || (line[i][j+1] != COIN))
               {
               cerr << "Error: horizontal string at (" << i << "," << j
                    << ") not attached to coins on both ends." << endl;
               exit(1);
               }

   for (i = 2; i <= last_row; i += 2)
      for (j = 1; j <= last_col; j += 2)

         if (line[i][j] == VSTRING) 
            if ((i == 0) || (line[i-1][j] != COIN) || (line[i+1][j] != COIN))
               {
               cerr << "Error: vertical string at (" << i << "," << j
                    << ") not attached to coins on both ends." << endl;
               exit(1);
               }
   }



void NimString::make_neighbors()
   {
   Node *node;
   int num_nodes = 0;
   int i, j;

   // make the nodes array and count the total
   // ----------------------------------------
   for (i = 1; i < last_row+2; i += 2)
      for (j = 1; j < last_col+2; j += 2)

         if (line[i][j] == COIN)
            {
            num_nodes++;
            nodes[i][j] = new Node( i, j );
            }
         else
            nodes[i][j] = NULL;
  
   stub = new STUB( num_nodes );

   int k = 0;
   for (i = 1; i < last_row+1; i += 2)
      for (j = 1; j < last_col+1; j += 2)

         if (line[i][j] == COIN)
            {
            stub->nodes[k] = node = nodes[i][j];
            k++;

            // set neighboring nodes
            // ---------------------
            if ((i > 1) && (line[i-1][j] == VSTRING))
               node->neigh[North] = nodes[i-2][j];
	
            if ((j > 1) && (line[i][j-1] == HSTRING))
               node->neigh[West] = nodes[i][j-2];
	
            if ((i+2 <= last_row) && (line[i+1][j] == VSTRING))
               node->neigh[South] = nodes[i+2][j];

            if ((j+2 <= last_col) && (line[i][j+1] == HSTRING))
               node->neigh[East]  = nodes[i][j+2];

            // set neighboring walls 
            // ---------------------
            if ((i > 0) && (line[i-1][j] == NORTHWALL))
               node->neigh[North] = WallNode;
	
            if ((j > 0) && (line[i][j-1] == WESTWALL))
               node->neigh[West] = WallNode;
	  
            if ((i <= last_row) && (line[i+1][j] == SOUTHWALL))
               node->neigh[South] = WallNode;
	
            if ((j <= last_col) && (line[i][j+1] == EASTWALL))
               node->neigh[East] = WallNode;	
            }
   }



void NimString::make_bitmasks()
   {
   CONFIG mask  = max_bit_64;
   conf = 0;

   for (int i = 1; i <= rows; i++)
      {
      bool left_adjacent = false;
      for (int j = 1; j <= cols; j++)

         make_mask_dir( i, j, West, East, left_adjacent, mask );
      }

   for (int i = 1; i <= cols; i++)
      {
      bool above_adjacent = false;
      for (int j = 1; j <= rows; j++)

         make_mask_dir( j, i, North, South, above_adjacent, mask);
      }

   if (mask < (MAX_NIM >> 1))
      {
      cerr << "ERROR: Input too large -- too many potential strings." << endl;
      exit(1);
      }

   conf &= (~LOW_MASK);              // mask off lower bits
   }



void NimString::make_mask_dir( int curr1, int curr2, Direction d1,
        Direction d2, bool &has_adj_node, CONFIG &mask )
   {
   int r = 1 + ((curr1 - 1) << 1);
   int c = 1 + ((curr2 - 1) << 1);

   Node *node = nodes[r][c];

   if (! node)
      {
      has_adj_node = false;
      return;
      }

   if (! has_adj_node)
      {
      if (node->neigh[d1]) {node->mask[d1] = mask; conf |= mask;}
      mask >>= 1;
      }

   else if (node->neigh[d1])
      node->mask[d1] = node->neigh[d1]->mask[d2];

   if (node->neigh[d2]) {node->mask[d2] = mask; conf |= mask;}

   mask >>= 1;
   has_adj_node = true;
   }


void NimString::print_game()
   {
   for (int i = 0; i < last_col+2; i++)
      line[last_row+2][i] = ' ';

   line[last_row+2][last_col+1] = 0;

   for (int i = 0; i < stub->num_nodes; i++)
      {
      Node *node = stub->nodes[i];
      int r = node->row;
      int c = node->col;

      line[r-1][c] = line[r][c+1] = line[r+1][c] = line[r][c-1] = ' ';

      if (has_string( node, conf, North )) 
         line[r-1][c] = (node->neigh[North]->ground) ? NORTHWALL : VSTRING;

      if (has_string( node, conf, East )) 
         line[r][c+1] = (node->neigh[East]->ground) ? EASTWALL : HSTRING;

      if (has_string( node, conf, South )) 
         line[r+1][c] = (node->neigh[South]->ground) ? SOUTHWALL : VSTRING;
      

      if (has_string( node, conf, West )) 
         line[r][c-1] = (node->neigh[West]->ground) ? WESTWALL : HSTRING;
      }


   for (int i = 0; i < last_row + 2; i++)
      {
      for (int j = 0; j < last_col + 2; j++)

         if (line[i][j] >= ' ' && line[i][j] <= '|')
            cout.put( line[i][j] );
         else
            break;

      cout << "\n";
      }

   cout << endl;
   }


void NimString::print_followers()
   {
   for (int i = 0; i < stub->num_nodes; i++)
      {
      Node *node = stub->nodes[i];
      int r = node->row;
      int c = node->col;

      // for each direction
      if (has_string( node, conf, North )) 
         if ((line[r-1][c] < '0' || line[r-1][c] > '9') &&
             (line[r-1][c] < 'A' || line[r-1][c] > 'F'))
            line[r-1][c] = to_ascii( find_value( conf & ~node->mask[North] ) );

      if (has_string( node, conf, East )) 
         if ((line[r][c+1] < '0' || line[r][c+1] > '9') &&
             (line[r][c+1] < 'A' || line[r][c+1] > 'F'))
            line[r][c+1] = to_ascii( find_value( conf & ~node->mask[East] ) );

      if (has_string( node, conf, South )) 
         if ((line[r+1][c] < '0' || line[r+1][c] > '9') &&
             (line[r+1][c] < 'A' || line[r+1][c] > 'F'))
            line[r+1][c] = to_ascii( find_value( conf & ~node->mask[South] ) );

      if (has_string( node, conf, West )) 
         if ((line[r][c-1] < '0' || line[r][c-1] > '9') &&
             (line[r][c-1] < 'A' || line[r][c-1] > 'F'))
            line[r][c-1] = to_ascii( find_value( conf & ~node->mask[West] ) );
      }


   for (int i = 0; i < last_row + 2; i++)
      {
      for (int j=0; j < last_col + 2; j++)

         if (line[i][j] >= ' ' && line[i][j] <= '|')
            cout.put( line[i][j] );
         else
            break;

      cout << "\n";
      }
   cout << endl;      // flush output stream
   }



inline char NimString::to_ascii( char v )
   {
   if (v >= 0 && v < 10) return (48 + v);

   if (v >= 10 && v < 16) return (v + 55);
  
   if (v == LOONY) return 'L';
  
   return '?';
   }


char NimString::find_value( CONFIG config )
   {
   if (config == 0) return 0;

   char value = htable->find( config );
   if (value != NOT_FOUND)
      {
      if (value == LOONY_TABLE) return LOONY;
      return value;
      }

   CONFIG config1, config2;
   if (decompose( config, config1, config2 ))
      {
      char value1 = find_value( config1 );
      char value2 = find_value( config2 );
      return nim_sum( value1, value2 );
      }
 
   value = check_capturable( config );
   if (value != NOTCAPTURED) return value;

   char mex_array[ MAX_NIM ];  
   for (int i=0; i < MAX_NIM; i++)
      mex_array[i] = 0;

   for (CONFIG filter = 1; filter > 0; filter <<= 1)
      {
      config1 = config & ~filter;
      if (config != config1)
         {
         value = find_value( config1 );
         if (value != LOONY)
            mex_array[ (int) value ] = 1;
         }
      }

   value = mex( mex_array );
   htable->insert( config, value );
   return value;
   }



int NimString::decompose( const CONFIG &config,CONFIG &config1,CONFIG &config2)
   {
   int numNodes = stub->num_nodes;
   int i;
   Node *node;

   config1 = 0;
   config2 = 0;

   for (i=0; i < numNodes; i++)
      {
      node = stub->nodes[i];
      node->visited = false;
      }

   for (i = 0; i < numNodes; i++)
      {
      node = stub->nodes[i];
      if (! node->visited)
         {
         dfs( node, config, config1 );

         if (config1 != 0 && config != config1)
            {
            config2 = config  ^ config1;
            return 1;
            }

         return 0;
         }
      }

   return 0;
   }



void NimString::dfs( Node *node, const CONFIG &config, CONFIG &config1 ) 
   {
   node->visited = true;

   for (int dir=0; dir < 4; dir++)

      if (has_string( node, config, dir ))
         {
         config1 = config1 | (node->mask[dir]);
         Node *nextnode = node->neigh[dir];
         if (! (nextnode->visited)) dfs( nextnode, config, config1 );
         }
   }



char NimString::check_capturable( const CONFIG &config )
   {
   int len = stub->num_nodes;

   for (int i = 0; i < len; i++)
      {
      Node *node = stub->nodes[i];
      char move_type = node_is_capturable( node, config );
      if (move_type == LOONY) return LOONY;
      if (move_type == TAKE)
         return find_value( remove_edges( TAKE_node, config ) );
      }

   return NOTCAPTURED;
   }



char NimString::node_is_capturable( Node *node, const CONFIG &config )
   {
   Node *nextnode=NULL;
   int dir, count[4], countn[4];
   int numStringsAttached = 0;

   // a node may be capturable if it has only one string attached to it.
   // -----------------------------------------------------------------
   for (dir = 0; dir < 4; dir++)
      {
      count[dir] = has_string( node, config, dir );
      numStringsAttached += count[dir];
      }

   if (numStringsAttached != 1) return NOTCAPTURED;

   for (dir = 0; dir < 4; dir++)
      if (count[dir]) {nextnode = node->neigh[dir]; break;}

   numStringsAttached = 0;
   for (dir = 0; dir < 4; dir++)
      {
      countn[dir] = has_string( nextnode, config, dir );
      numStringsAttached += countn[dir];
      }

   if (nextnode->ground  || numStringsAttached != 2)
      {
      TAKE_node = node;
      return TAKE;
      }

   // last take possibility is *-*-*. Find other neighbor of nextnode
   // ---------------------------------------------------------------
   if (count[North])
      {
      if (countn[North]) node = nextnode->neigh[North];
      else if (countn[East]) node = nextnode->neigh[East];
      else if (countn[West]) node = nextnode->neigh[West];
      }
   else if (count[South])
      {
      if (countn[South]) node = nextnode->neigh[South];
      else if (countn[East]) node = nextnode->neigh[East];
      else if (countn[West]) node = nextnode->neigh[West];
      }
   else if (count[West])
      {
      if (countn[West]) node = nextnode->neigh[West];
      else if (countn[North]) node = nextnode->neigh[North];
      else if (countn[South]) node = nextnode->neigh[South];
      }
   else if (count[East])
      {
      if (countn[East]) node = nextnode->neigh[East];
      else if (countn[North]) node = nextnode->neigh[North];
      else if (countn[South]) node = nextnode->neigh[South];
      }

   if (! node->ground && num_strings_attached( node, config ) == 1)
      {
      TAKE_node = nextnode;
      return TAKE;
      }

   return LOONY;
   }



char NimString::mex( char A[] )
   {
   int i;
   for (i=0; i < MAX_NIM; i++)
      if (! A[i]) return i;
   return i;
   }


inline char NimString::nim_sum( char s1, char s2 )
   {
   return ((s1 == LOONY || s2 == LOONY) ? LOONY: (s1 ^ s2));
   }


inline int NimString::num_strings_attached( Node *node, const CONFIG &config )
   {
   int sum = 0;

   for (int dir = 0; dir < 4; dir++)
      sum += has_string( node, config, dir );

   return sum;
   }



HT::HT()
   {
   ht = (int *) malloc( NUM_HASHCHAINS * sizeof( int ) );
   int *hte = ht + NUM_HASHCHAINS;
   for (int *htp = ht; htp < hte; htp++)
      *htp = -1;

   entry = (HT_Entry *) malloc( NUM_HASH_ENTRIES * sizeof( HT_Entry ) );
   numEntries = 0;
   if (entry == NULL)
      {
      cerr << "Not enough memory for the hash table.\n";
      cerr << "Reduce the value of HASH_N and recompile." << endl;
      exit(1);
      }
   }



Ulong HT::hash( CONFIG config )
   {
   Ulong h = 0;                // hash code value
   register int i;

   for (h=0, i=0; i < 2; i++) 
      {
      h += (config & LONGMASK);
      h += (h<<10);
      h ^= (h>>6);
      config >>= 32;
      }

   h += (h<<3);
   h ^= (h>>11);
   h += (h<<15);
   h &= (NUM_HASHCHAINS - 1);
   return h;
   }



void HT::insert( const CONFIG &config, char value )
   {
   if (numEntries >= NUM_HASH_ENTRIES)
      {
      cerr << "No room left in hash table" << endl;
      exit(1);
      }

   if (value != LOONY && value > BIG_NIM)
      {
      cout << "WARNING: A sub-position has nim-value > " << BIG_NIM
           << " Results may not be correct!";
      value = BIG_NIM;
      }

   else if (value == LOONY) value = LOONY_TABLE;

   Ulong key = hash( config );
   entry[numEntries].config_and_value = config | value;
   entry[numEntries].next = ht[ key ];
   ht[key] = numEntries++;
   }



char HT::find( const CONFIG &config )
   {
   Ulong key = hash( config );

   for (int he = ht[ key ]; he != -1; he = entry[he].next)
      if (config_of( entry[he].config_and_value ) == config)
         return value_of( entry[he].config_and_value );

   return NOT_FOUND;
   }


inline CONFIG HT::config_of( const CONFIG &c )
   {
   return (c & ~LOW_MASK);
   }

inline char HT::value_of( const CONFIG &c )
   {
   return (c & LOW_MASK);
   }



Node::Node()
   {
   for (int dir = 0; dir < 4; dir++)
      {
      neigh[dir] = NULL;
      mask[dir] = 0;
      }
   ground = false;
   visited = false;
   }



Node::Node( int r, int c )
   {
   for (int dir = 0; dir < 4; dir++)
      {
      neigh[dir] = NULL;
      mask[dir] = 0;
      }
   ground = false;
   visited = false;
   row = r; col = c;
   }
