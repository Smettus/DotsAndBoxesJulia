#include <iostream>
#include <fstream>

using namespace std;

typedef unsigned int  Uint;
typedef unsigned long Ulong;
typedef enum {North=0, South, East, West} Direction;

const short LOW_BITS = 4;            // number of bits used for nim values

const short MAX_ROWS = 20;           // rows of input text (not rows of coins!)
const short MAX_COLS = 20;           // columns of input text

#if defined(_MSC_VER) || defined(__BORLANDC__)  // Microsoft C++ or Borland C++
   typedef unsigned __int64    CONFIG;
#else 
   typedef unsigned long long  CONFIG;
#endif 

const Ulong HASH_N = 26;
const Ulong NUM_HASHCHAINS = 1 << HASH_N;
const Ulong NUM_HASH_ENTRIES = 1 << (HASH_N-1);   // load factor <= 1/2

const short MAX_NIM = (1 << LOW_BITS);  // max size of mex table
const short LOONY = 100;             // indicates nim value is loony
const short TAKE = 99;               // indicates a free coin
const short NOTCAPTURED = 98;        // no coins are capturable
const short NOT_FOUND = 97;          // config not found in hash table
const short BIG_NIM = MAX_NIM-2;     // nim values >= BIG_nim stored as BIG_NIM
const short LOONY_TABLE = MAX_NIM-1; // table storage value for LOONY

const Ulong LONGMASK = (((Ulong)1) << 31) - 1;
const CONFIG max_bit_64 = (((CONFIG)1) << 63);
const CONFIG LOW_MASK = MAX_NIM - 1;    // used to mask lower bits of a config

const char NORTHWALL = '^';
const char SOUTHWALL = 'v';
const char EASTWALL  = '>';
const char WESTWALL  = '<';
const char COIN      = '*';
const char HSTRING   = '-';
const char VSTRING   = '|';



class Node
   {
   public:
      Node();
      Node( int, int );

      int  row, col;                // row and column of node
      bool ground;                  // this is a ground node
      bool visited;                 // mark for dfs
      Node *neigh[4];               // Neighboring nodes
      CONFIG mask[4];               // bit mask for each neighbor/edge
   };


class STUB; class HT;


class NimString
   {
   public:
      NimString( ifstream & );
      char find_value( CONFIG );

   private:
      void read_input( ifstream & );
      void is_rectangular( void );
      void make_neighbors( void );
      void make_bitmasks( void );
      void make_mask_dir( int, int, Direction, Direction, bool &, CONFIG & );
      void print_game( void );
      void print_masks( void );
      void print_bits( CONFIG );
      void print_followers( void );
      inline char to_ascii( char );

      int decompose( const CONFIG &, CONFIG &, CONFIG &);
      void dfs( Node *, const CONFIG &, CONFIG & );
      char check_capturable( const CONFIG & );
      char node_is_capturable( Node *, const CONFIG & );
      char mex( char [] );
      inline char nim_sum( char, char );
      inline int num_strings_attached( Node *, const CONFIG & );

      inline int has_string( Node *node, const CONFIG &config, int dir ) {
         return (config & node->mask[dir]) > 0; }

      inline CONFIG remove_edges( Node *take, const CONFIG &config ) {
         return config & ~( take->mask[North] | take->mask[South] |
                            take->mask[East]  | take->mask[West] ); }

      HT *htable;                        // hash table
      STUB *stub;                        // list of nodes
      char line[MAX_ROWS][MAX_COLS];     // holds input
      Node *nodes[MAX_ROWS][MAX_COLS];   // temporary
      int rows, cols;                    // number of rows and cols in input
      Node *WallNode;                    // ground node
      CONFIG conf;                       // the configuration
      int last_row;                      // last input row containing a coin
      int last_col;                      // last input column containing a coin
      Node *TAKE_node;                   // capturable node
   };



class STUB
   {
   public:
      STUB( int n ) { nodes = new Node*[ n ]; num_nodes = n; }

      int num_nodes;
      Node **nodes;
   };



class HT_Entry
   {
   public:
      CONFIG config_and_value;
      int next;
   };



class HT
   {
   public:
      HT();
      void insert( const CONFIG &, char );
      char find( const CONFIG & );
      
   private:
      Ulong hash( CONFIG );             // the hash function
      int *ht;                          // hash table headers
      HT_Entry *entry;                  // array of entries
      Uint numEntries;                  // current number of entries in table

      inline CONFIG config_of( const CONFIG & );
      inline char value_of( const CONFIG & );
   };
