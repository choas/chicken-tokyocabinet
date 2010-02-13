___declare(type, "LIST;(nonnull-c-pointer \"TCLIST\");tc-list-ptr")
___declare(type, "MAP;(nonnull-c-pointer \"TCMAP\");tc-map-ptr")
___declare(substitute, "^tclist;%tc-list-")
___declare(substitute, "^tcmap;%tc-map-")

LIST tclistnew();
void *tclistpop(LIST list, ___pointer int *sp);
void tclistpush(LIST list, ___scheme_pointer ptr, int siz);
void tclistdel(LIST list);

MAP tcmapnew();
void tcmapdel(MAP map);
void tcmapput(MAP map, ___scheme_pointer kbuf, int ksiz,
	               ___scheme_pointer vbuf, int vsiz);
bool tcmapout(MAP map, ___scheme_pointer kbuf, int ksiz);
const void *tcmapget(MAP map, ___scheme_pointer kbuf, int ksiz, ___pointer int *sp);
void tcmapiterinit(MAP map);
const void *tcmapiternext(MAP map, ___pointer int *sp);
