___declare(type, "TDB;(nonnull-c-pointer \"TCTDB\");tc-tdb-ptr")
___declare(type, "QRY;(nonnull-c-pointer \"TDBQRY\");tc-tdb-qry-ptr")
___declare(substitute, "^tctdbqry;%tc-tdb-qry-")
___declare(substitute, "^tctdb;%tc-tdb-")

TDB tctdbnew();
void tctdbdel(TDB tdb);
bool tctdbopen(TDB tdb, char *file, int flags);
bool tctdbclose(TDB tdb);
bool tctdbsetmutex(TDB tdb);
bool tctdbsetcache(TDB tdb, ___s32 rcnum, ___s32 lcnum, ___s32 ncnum);
bool tctdbtune(TDB tdb, int bnum, int apow, int fpow, int opts);
bool tctdbiterinit(TDB tdb);
void *tctdbiternext(TDB tdb, ___pointer int *sp);
bool tctdbsync(TDB tdb);
MAP *tctdbget(TDB tdb, ___scheme_pointer pkbuf, int pksiz);
bool tctdbput(TDB tdb, ___scheme_pointer pkbuf, int pksiz, MAP cols);
bool tctdbout(TDB tdb, ___scheme_pointer pkbuf, int pksiz);
bool tctdbsetxmsiz(TDB tdb, ___s64 xmsiz);
bool tctdbvanish(TDB tdb);
bool tctdbcopy(TDB tdb, const char *path);
bool tctdbtranbegin(TDB tdb);
bool tctdbtrancommit(TDB tdb);
bool tctdbtranabort(TDB tdb);
int64_t tctdbrnum(TDB tdb);   /* no result type for uint64_t */
int64_t tctdbfsiz(TDB tdb);
bool tctdbsetindex(TDB tdb, char *name, int type);
int64_t tctdbgenuid(TDB tdb);
QRY *tctdbqrynew(TDB tdb);
void tctdbqrydel(QRY qry);
void tctdbqryaddcond(QRY qry, char *name, int op, char *expr);
void tctdbqrysetorder(QRY qry, char *name, int type);
void tctdbqrysetlimit(QRY qry, int max, int skip);
LIST *tctdbqrysearch(QRY qry);
