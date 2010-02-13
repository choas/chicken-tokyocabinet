___declare(type, "HDB;(nonnull-c-pointer \"TCHDB\");tc-hdb-ptr")
___declare(substitute, "^tchdb;%tc-hdb-")

HDB tchdbnew();
void tchdbdel(HDB hdb);
bool tchdbopen(HDB hdb, char *file, int flags);
bool tchdbclose(HDB hdb);
bool tchdbsetmutex(HDB hdb);
bool tchdbsetcache(HDB hdb, ___s32 rcnum);
bool tchdbtune(HDB hdb, int bnum, int apow, int fpow, int opts);
bool tchdbiterinit(HDB hdb);
void *tchdbiternext(HDB hdb, ___pointer int *sp);
bool tchdbsync(HDB hdb);
void *tchdbget(HDB hdb, ___scheme_pointer kbuf, int ksiz, ___pointer int *sp);
bool tchdbput(HDB hdb, ___scheme_pointer kbuf, int ksiz,
                       ___scheme_pointer vbuf, int vsiz);
bool tchdbout(HDB hdb, ___scheme_pointer kbuf, int ksiz);
bool tchdbsetxmsiz(HDB hdb, ___s64 xmsiz);
/* int tchdbaddint(TCHDB *hdb, const void *kbuf, int ksiz, int num); */
/* int tchdbadddouble(TCHDB *hdb, const void *kbuf, int ksiz, int double); */
bool tchdbvanish(HDB hdb);
bool tchdbcopy(HDB hdb, const char *path);
bool tchdbtranbegin(HDB hdb);
bool tchdbtrancommit(HDB hdb);
bool tchdbtranabort(HDB hdb);
int64_t tchdbrnum(HDB hdb);   /* no result type for uint64_t */
int64_t tchdbfsiz(HDB hdb);
