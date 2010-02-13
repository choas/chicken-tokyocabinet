___declare(type, "BDB;(nonnull-c-pointer \"TCBDB\");tc-bdb-ptr")
___declare(type, "CUR;(nonnull-c-pointer \"BDBCUR\");tc-bdb-cur-ptr")
___declare(substitute, "^tcbdb;%tc-bdb-")

BDB tcbdbnew();
void tcbdbdel(BDB bdb);
bool tcbdbopen(BDB bdb, char *file, int flags);
bool tcbdbclose(BDB bdb);
bool tcbdbsetmutex(BDB bdb);
bool tcbdbsetcache(BDB bdb, ___s32 lcnum, ___s32 ncnum);
bool tcbdbtune(BDB bdb, int lmemb, int nmemb, int bnum, int apow,
	       int fpow, int opts);
CUR tcbdbcurnew(BDB bdb);
bool tcbdbcurfirst(CUR cur);
void *tcbdbcurkey(CUR cur, ___pointer int *sp);
void *tcbdbcurval(CUR cur, ___pointer int *sp);
bool tcbdbcurnext(CUR cur);
void tcbdbcurdel(CUR cur);
bool tcbdbsync(BDB bdb);
void *tcbdbget(BDB bdb, ___scheme_pointer kbuf, int ksiz, ___pointer int *sp);
LIST *tcbdbget4(BDB bdb, ___scheme_pointer kbuf, int ksiz);
LIST *tcbdbfwmkeys(BDB bdb, ___scheme_pointer pbuf, int psiz, int max);
bool tcbdbput(BDB bdb, ___scheme_pointer kbuf, int ksiz,
                       ___scheme_pointer vbuf, int vsiz);
bool tcbdbputdup(BDB bdb, ___scheme_pointer kbuf, int ksiz,
		          ___scheme_pointer vbuf, int vsiz);
bool tcbdbputdup3(BDB bdb, ___scheme_pointer kbuf, int ksiz, const LIST vals);
bool tcbdbout(BDB bdb, ___scheme_pointer kbuf, int ksiz);
bool tcbdbsetxmsiz(BDB bdb, ___s64 xmsiz);
bool tcbdbvanish(BDB bdb);
bool tcbdbcopy(BDB bdb, const char *path);
bool tcbdbtranbegin(BDB bdb);
bool tcbdbtrancommit(BDB bdb);
bool tcbdbtranabort(BDB bdb);
int64_t tcbdbrnum(BDB bdb);	/* no result type for uint64_t */
int64_t tcbdbfsiz(BDB bdb);
