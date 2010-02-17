;;;; tokyocabinet.scm -- Tokyo Cabinet DBM bindings for Chicken
;;
;; Copyright (c) 2008-2009 Alex Shinn
;; All rights reserved.
;;
;; BSD-style license: http://www.debian.org/misc/bsd.license

(require-extension lolevel) ; free

(module tokyocabinet
 (tc-list-new tc-list-del
  tc-list-pop tc-list-push tc-list-fold
  tc-map-new tc-map-del
  tc-map-put! tc-map-out! tc-map-get
  tc-map-iter-init tc-map-iter-next
  tc-map-fold
  TC_HDBTLARGE TC_HDBTDEFLATE TC_HDBTBZIP TC_HDBTTCBS
  TC_HDBOWRITER TC_HDBOREADER TC_HDBOCREAT TC_HDBOTRUNC
  TC_HDBONOLCK TC_HDBOLCKNB
  tc-hdb-open tc-hdb-close
  tc-hdb-put! tc-hdb-out! tc-hdb-get
  tc-hdb-fold
  tc-hdb-iter-init tc-hdb-iter-next
  tc-hdb-sync tc-hdb-vanish tc-hdb-copy
  tc-hdb-path
  tc-hdb-transaction-begin tc-hdb-transaction-commit tc-hdb-transaction-abort
  tc-hdb-record-count tc-hdb-file-size
  TC_BDBTLARGE TC_BDBTDEFLATE TC_BDBTBZIP TC_BDBTTCBS
  TC_BDBOWRITER TC_BDBOREADER TC_BDBOCREAT TC_BDBOTRUNC
  TC_BDBONOLCK TC_BDBOLCKNB
  tc-bdb-open tc-bdb-close
  tc-bdb-put! tc-bdb-putdup! tc-bdb-out! tc-bdb-get
  tc-bdb-get-tc-list tc-bdb-put-tc-list!
  tc-bdb-fold
  tc-bdb-cur-new tc-bdb-cur-first tc-bdb-cur-next tc-bdb-cur-del
  tc-bdb-cur-key tc-bdb-cur-val tc-bdb-fwm-keys
  tc-bdb-sync tc-bdb-vanish tc-bdb-copy
  tc-bdb-path
  tc-bdb-transaction-begin tc-bdb-transaction-commit tc-bdb-transaction-abort
  tc-bdb-record-count tc-bdb-file-size
  TC_TDBTLARGE TC_TDBTDEFLATE TC_TDBTBZIP TC_TDBTTCBS
  TC_TDBOWRITER TC_TDBOREADER TC_TDBOCREAT TC_TDBOTRUNC 
  TC_TDBONOLCK  TC_TDBOLCKNB
  TC_TDBITLEXICAL TC_TDBITDECIMAL
;;  TC_TDBITTOKEN TC_TDBITQGRAM 
  TC_TDBITOPT TC_TDBITVOID TC_TDBITKEEP
  TC_TDBQCSTREQ TC_TDBQCSTRINC TC_TDBQCSTRBW TC_TDBQCSTREW
  TC_TDBQCSTRAND TC_TDBQCSTROR TC_TDBQCSTROREQ TC_TDBQCSTRRX
  TC_TDBQCNUMEQ TC_TDBQCNUMGT TC_TDBQCNUMGE TC_TDBQCNUMLT
  TC_TDBQCNUMLE TC_TDBQCNUMBT TC_TDBQCNUMOREQ
;;  TC_TDBQCFTSPH TC_TDBQCFTSAND TC_TDBQCFTSOR TC_TDBQCFTSEX
  TC_TDBQCNEGATE TC_TDBQCNOIDX
  TC_TDBQOSTRASC TC_TDBQOSTRDESC TC_TDBQONUMASC TC_TDBQONUMDESC
  tc-tdb-open tc-tdb-close
  tc-tdb-put! tc-tdb-put-tc-map! tc-tdb-out! tc-tdb-get
  tc-tdb-fold
  tc-tdb-iter-init tc-tdb-iter-next tc-tdb-fold
  tc-tdb-set-index
  tc-tdb-sync tc-tdb-vanish tc-tdb-copy
  tc-tdb-path
  tc-tdb-transaction-begin tc-tdb-transaction-commit tc-tdb-transaction-abort
  tc-tdb-record-count tc-tdb-file-size tc-tdb-gen-uid
  tc-tdb-qry-new tc-tdb-qry-del
  tc-tdb-qry-add-cond tc-tdb-qry-set-order tc-tdb-qry-set-limit
  tc-tdb-qry-search
)

(import scheme chicken foreign extras easyffi (only lolevel free))

(declare
  (foreign-declare "

#include <tcutil.h>
#include <tchdb.h>
#include <tcbdb.h>
#include <tctdb.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#define copy_string_result(ptr, len, str)     (C_memcpy(C_c_string(str), (char *)C_block_item(ptr, 0), C_unfix(len)), C_SCHEME_UNDEFINED)

"))

(define-foreign-variable +max-string-length+ int "C_HEADER_SIZE_MASK")

;; Copy size bytes from ptr into new string and free ptr.
;; Like c-string* return type but does not use null terminator.
;; Note: Exception handling imposes an unacceptable overhead.
(define (sized-c-string* ptr size #!optional (where 'sized-c-string*))
  (when (> size +max-string-length+)
    (free ptr)
    (error where "string length too long" size))
  (let ((val (make-string size)))
    (##core#inline "copy_string_result" ptr size val)
    (free ptr)
    val))

;; Copy size bytes from ptr into new string.
(define (sized-c-string*-nofree ptr size #!optional (where 'sized-c-string*))
  (when (> size +max-string-length+)
    (error where "string length too long" size))
  (let ((val (make-string size)))
    (##core#inline "copy_string_result" ptr size val)
    val))

;;; Utility API

(define-record tc-list ptr)

(define-foreign-type tc-list
  (nonnull-c-pointer "TCLIST")
  ; tc-list-ptr
  )

(define-record tc-map ptr)

(define-foreign-type tc-map
  (nonnull-c-pointer "TCMAP")
  ; tc-map-ptr
  )

#>? #include "tcutilapi.h" <#

(define (tc-list-new)
  (make-tc-list (%tc-list-new)))

(define (tc-list-pop tc-list)
  (let-location ((size int))
    (and-let* ((ptr (%tc-list-pop tc-list (location size))))
      (sized-c-string* ptr size 'tc-list-pop))))

(define (tc-list-push tc-list value)
  (%tc-list-push tc-list value (string-length value)))

(define (tc-list-del tc-list)
  (begin (%tc-list-del tc-list)
         (tc-list-ptr-set! tc-list #f)  ; prevent further use
         #t))
  
(define (tc-list-fold tc-list kons knil)
  (let lp ((acc knil))
    (let ((val (tc-list-pop tc-list)))
      (if (not val)
          acc
          (lp (kons val acc))))))

(define (tc-map-new)
  (make-tc-map (%tc-map-new)))

(define (tc-map-del tc-map)
  (begin (%tc-map-del tc-map)
         (tc-map-ptr-set! tc-map #f)
         #t))

(define (tc-map-put! tc-map key value)
  (%tc-map-put tc-map key (string-length key)
               value (string-length value)))

(define (tc-map-out! tc-map key)
  (%tc-map-out tc-map key (string-length key)))

(define (tc-map-get tc-map key)
  (let-location ((size int))
    (and-let* ((ptr (%tc-map-get tc-map key
                                 (string-length key) (location size))))
      (sized-c-string*-nofree ptr size 'tc-map-get))))

(define tc-map-iter-init %tc-map-iterinit)
(define (tc-map-iter-next tc-map)
  (let-location ((size int))
    (and-let* ((ptr (%tc-map-iternext tc-map (location size))))
      (sized-c-string*-nofree ptr size 'tc-map-iter-next))))

(define (tc-map-fold tc-map kons knil)
  (tc-map-iter-init tc-map)
  (let lp ((acc knil))
    (let ((key (tc-map-iter-next tc-map)))
      (if (not key)
          acc
          (let ((val (tc-map-get tc-map key)))
            (lp (kons key val acc)))))))

;;; Hash table API

;; tc-hdb-tune flags
(define-foreign-variable HDBTLARGE int "HDBTLARGE")
(define-foreign-variable HDBTDEFLATE int "HDBTDEFLATE")
(define-foreign-variable HDBTBZIP int "HDBTBZIP")
(define-foreign-variable HDBTTCBS int "HDBTTCBS")

(define TC_HDBTLARGE HDBTLARGE)
(define TC_HDBTDEFLATE HDBTDEFLATE)
(define TC_HDBTBZIP HDBTBZIP)
(define TC_HDBTTCBS HDBTTCBS)

;; tc-hdb-open flags
(define-foreign-variable HDBOWRITER int "HDBOWRITER")
(define-foreign-variable HDBOREADER int "HDBOREADER")
(define-foreign-variable HDBOCREAT int "HDBOCREAT")
(define-foreign-variable HDBOTRUNC int "HDBOTRUNC")
(define-foreign-variable HDBONOLCK int "HDBONOLCK")
(define-foreign-variable HDBOLCKNB int "HDBOLCKNB")

(define TC_HDBOWRITER HDBOWRITER)
(define TC_HDBOREADER HDBOREADER)
(define TC_HDBOCREAT HDBOCREAT)
(define TC_HDBOTRUNC HDBOTRUNC)
(define TC_HDBONOLCK HDBONOLCK)
(define TC_HDBOLCKNB HDBOLCKNB)

(define-record tc-hdb ptr path)
(define-record-printer (tc-hdb hdb port)
  (fprintf port "#<tc-hdb ~A on ~S>"
           (or (tc-hdb-ptr hdb) "(closed)")
           (tc-hdb-path hdb)))

(define-foreign-type hdb
  (nonnull-c-pointer "TCHDB")
  ; tc-hdb-ptr
  )

#>? #include "tchdbapi.h" <#

(define (tc-hdb-open file
                     #!key
                     (flags (fx+ HDBOWRITER (fx+ HDBOREADER HDBOCREAT)))
                     (mutex? #f)
                     (num-buckets #f)
                     (record-alignment #f)
                     (num-free-blocks #f)
                     (tune-opts #f)
                     (cache-limit #f)
                     (mmap-size #f))
  (let ((hdb (make-tc-hdb (%tc-hdb-new) file)))
    (and (tc-hdb-ptr hdb)
         ;; make sure all the specified keyword settings succeed, and
         ;; return the hdb record
         (or (and
              (or (not mutex?) (%tc-hdb-setmutex hdb))
              (or (not cache-limit) (%tc-hdb-setcache hdb cache-limit))
              (or (not mmap-size) (%tc-hdb-setxmsiz hdb mmap-size))
              (or (not (or num-buckets record-alignment num-free-blocks
                           tune-opts))
                  (%tc-hdb-tune hdb
                                (or num-buckets 0)
                                (or record-alignment -1)
                                (or num-free-blocks -1)
                                (or tune-opts 0)))
              (%tc-hdb-open hdb file flags)
              hdb)
             (begin
               ;; clean up and return #f if any of the functions failed
               (%tc-hdb-del hdb)
               #f)))))

(define (tc-hdb-close hdb)
  (and (%tc-hdb-close hdb)
       (begin (%tc-hdb-del hdb)
              (tc-hdb-ptr-set! hdb #f) ; prevent further use
              #t)))

(define (tc-hdb-put! hdb key value)
  (%tc-hdb-put hdb key (string-length key)
               value (string-length value)))

(define (tc-hdb-out! hdb key)
  (%tc-hdb-out hdb key (string-length key)))

(define (tc-hdb-get hdb key)
  (let-location ((size int))
    (and-let* ((ptr (%tc-hdb-get hdb key
                                 (string-length key) (location size))))
      (sized-c-string* ptr size 'tc-hdb-get))))

(define tc-hdb-iter-init %tc-hdb-iterinit)
(define (tc-hdb-iter-next hdb)
  (let-location ((size int))
    (and-let* ((ptr (%tc-hdb-iternext hdb (location size))))
      (sized-c-string* ptr size 'tc-hdb-iter-next))))

(define (tc-hdb-fold hdb kons knil)
  (tc-hdb-iter-init hdb)
  (let lp ((acc knil))
    (let ((key (tc-hdb-iter-next hdb)))
      (if (not key)
          acc
          (let ((val (tc-hdb-get hdb key)))
            (lp (kons key val acc)))))))

(define tc-hdb-sync %tc-hdb-sync)
(define tc-hdb-vanish %tc-hdb-vanish)
(define tc-hdb-copy %tc-hdb-copy)
(define tc-hdb-transaction-begin  %tc-hdb-tranbegin)
(define tc-hdb-transaction-commit %tc-hdb-trancommit)
(define tc-hdb-transaction-abort  %tc-hdb-tranabort)
(define tc-hdb-record-count %tc-hdb-rnum)
(define tc-hdb-file-size %tc-hdb-fsiz)


;;; B+-tree API

;; tc-bdb-tune flags
(define-foreign-variable BDBTLARGE int "BDBTLARGE")
(define-foreign-variable BDBTDEFLATE int "BDBTDEFLATE")
(define-foreign-variable BDBTBZIP int "BDBTBZIP")
(define-foreign-variable BDBTTCBS int "BDBTTCBS")

(define TC_BDBTLARGE BDBTLARGE)
(define TC_BDBTDEFLATE BDBTDEFLATE)
(define TC_BDBTBZIP BDBTBZIP)
(define TC_BDBTTCBS BDBTTCBS)

;; tc-bdb-open flags
(define-foreign-variable BDBOWRITER int "BDBOWRITER")
(define-foreign-variable BDBOREADER int "BDBOREADER")
(define-foreign-variable BDBOCREAT int "BDBOCREAT")
(define-foreign-variable BDBOTRUNC int "BDBOTRUNC")
(define-foreign-variable BDBONOLCK int "BDBONOLCK")
(define-foreign-variable BDBOLCKNB int "BDBOLCKNB")

(define TC_BDBOWRITER BDBOWRITER)
(define TC_BDBOREADER BDBOREADER)
(define TC_BDBOCREAT BDBOCREAT)
(define TC_BDBOTRUNC BDBOTRUNC)
(define TC_BDBONOLCK BDBONOLCK)
(define TC_BDBOLCKNB BDBOLCKNB)

(define-record tc-bdb ptr path)
(define-record-printer (tc-bdb bdb port)
  (fprintf port "#<tc-bdb ~A on ~S>"
           (or (tc-bdb-ptr bdb) "(closed)")
           (tc-bdb-path bdb)))

(define-foreign-type bdb
  (nonnull-c-pointer "TCBDB")
  ; tc-bdb-ptr
  )

(define-record tc-bdb-cur ptr path)
(define-record-printer (tc-bdb-cur bdb-cur port)
  (fprintf port "#<tc-bdb-cur ~A on ~S>"
           (or (tc-bdb-cur-ptr bdb-cur) "(closed)")
           (tc-bdb-cur-path bdb-cur)))
  
(define-foreign-type bdb-cur
  (nonnull-c-pointer "BDBCUR")
  ; tc-bdb-cur-ptr
  )

#>? #include "tcbdbapi.h" <#

(define (tc-bdb-open file
                     #!key
                     (flags (fx+ BDBOWRITER (fx+ BDBOREADER BDBOCREAT)))
                     (mutex? #f)
                     (leaf-members #f)
                     (non-leaf-members #f)
                     (num-buckets #f)
                     (record-alignment #f)
                     (num-free-blocks #f)
                     (tune-opts #f)
                     (leaf-cache #f)
                     (non-leaf-cache #f)
                     (mmap-size #f))
  (let ((bdb (make-tc-bdb (%tc-bdb-new) file)))
    (and (tc-bdb-ptr bdb)
         ;; make sure all the specified keyword settings succeed, and
         ;; return the bdb record
         (or (and
              (or (not mutex?) (%tc-bdb-setmutex bdb))
              (or (not (or leaf-cache non-leaf-cache))
                  (%tc-bdb-setcache bdb
                                    (or leaf-cache 0)
                                    (or non-leaf-cache 0)))
              (or (not mmap-size) (%tc-bdb-setxmsiz bdb mmap-size))
              (or (not (or leaf-members non-leaf-members num-buckets
                           record-alignment num-free-blocks tune-opts))
                  (%tc-bdb-tune bdb
                                (or leaf-members 0)
                                (or non-leaf-members 0)
                                (or num-buckets 0)
                                (or record-alignment -1)
                                (or num-free-blocks -1)
                                (or tune-opts 0)))
              (%tc-bdb-open bdb file flags)
              bdb)
             (begin
               ;; clean up and return #f if any of the functions failed
               (%tc-bdb-del bdb)
               #f)))))
         
(define (tc-bdb-close bdb)
  (and (%tc-bdb-close bdb)
       (begin (%tc-bdb-del bdb)
              (tc-bdb-ptr-set! bdb #f) ; prevent further use
              #t)))

(define (tc-bdb-put! bdb key value)
  (%tc-bdb-put bdb key (string-length key)
               value (string-length value)))

(define (tc-bdb-putdup! bdb key value)
  (%tc-bdb-putdup bdb key (string-length key)
                  value (string-length value)))

(define (tc-bdb-out! bdb key)
  (%tc-bdb-out bdb key (string-length key)))

(define (tc-bdb-get bdb key)
  (let-location ((size int))
    (and-let* ((ptr (%tc-bdb-get bdb key
                                 (string-length key) (location size))))
      (sized-c-string* ptr size 'tc-bdb-get))))

;; delete tc-list when finished
(define (tc-bdb-get-tc-list bdb key)
  (let ((tc-list (make-tc-list (%tc-bdb-get4 bdb key (string-length key)))))
    (and (tc-list-ptr tc-list)
         tc-list)))

;; delete tc-list when finished
(define (tc-bdb-put-tc-list! bdb key tc-list)
  (%tc-bdb-putdup3 bdb key (string-length key) (tc-list-ptr tc-list)))

;; delete tc-list when finished
;; negative max for no limit
(define (tc-bdb-fwm-keys bdb prefix max)
  (let ((tc-list
         (make-tc-list (%tc-bdb-fwmkeys (string-length prefix) bdb prefix max))))
    (and (tc-list-ptr tc-list)
         tc-list)))

(define (tc-bdb-cur-new bdb)
  (make-tc-bdb-cur (%tc-bdb-curnew bdb) (tc-bdb-path bdb)))

(define tc-bdb-cur-first %tc-bdb-curfirst)
(define tc-bdb-cur-next %tc-bdb-curnext)

(define (tc-bdb-cur-del cur)
  (begin (%tc-bdb-curdel cur)
         (tc-bdb-cur-ptr-set! cur #f)
         #t))

(define (tc-bdb-cur-key cur)
  (let-location ((size int))
    (and-let* ((ptr (%tc-bdb-curkey cur (location size))))
      (sized-c-string* ptr size 'tc-bdb-cur-key))))

(define (tc-bdb-cur-val cur)
  (let-location ((size int))
    (and-let* ((ptr (%tc-bdb-curval cur (location size))))
      (sized-c-string* ptr size 'tc-bdb-cur-val))))

(define (tc-bdb-fold bdb kons knil)
  (let ((cur (tc-bdb-cur-new bdb)))
    (tc-bdb-cur-first cur)
    (let lp ((acc knil))
      (let ((key (tc-bdb-cur-key cur))
            (val (tc-bdb-cur-val cur)))
        (cond
          ((not (tc-bdb-cur-next cur))
           (tc-bdb-cur-del cur)
           (kons key val acc))
          (else (lp (kons key val acc))))))))

(define tc-bdb-sync %tc-bdb-sync)
(define tc-bdb-vanish %tc-bdb-vanish)
(define tc-bdb-copy %tc-bdb-copy)
(define tc-bdb-transaction-begin  %tc-bdb-tranbegin)
(define tc-bdb-transaction-commit %tc-bdb-trancommit)
(define tc-bdb-transaction-abort  %tc-bdb-tranabort)
(define tc-bdb-record-count %tc-bdb-rnum)
(define tc-bdb-file-size %tc-bdb-fsiz)

;;; Table API

;; tc-tdb-tune flags
(define-foreign-variable TDBTLARGE int "TDBTLARGE")
(define-foreign-variable TDBTDEFLATE int "TDBTDEFLATE")
(define-foreign-variable TDBTBZIP int "TDBTBZIP")
(define-foreign-variable TDBTTCBS int "TDBTTCBS")

(define TC_TDBTLARGE TDBTLARGE)
(define TC_TDBTDEFLATE TDBTDEFLATE)
(define TC_TDBTBZIP TDBTBZIP)
(define TC_TDBTTCBS TDBTTCBS)

;; tc-tdb-open flags
(define-foreign-variable TDBOWRITER int "TDBOWRITER")
(define-foreign-variable TDBOREADER int "TDBOREADER")
(define-foreign-variable TDBOCREAT int "TDBOCREAT")
(define-foreign-variable TDBOTRUNC int "TDBOTRUNC")
(define-foreign-variable TDBONOLCK int "TDBONOLCK")
(define-foreign-variable TDBOLCKNB int "TDBOLCKNB")

(define TC_TDBOWRITER TDBOWRITER)
(define TC_TDBOREADER TDBOREADER)
(define TC_TDBOCREAT TDBOCREAT)
(define TC_TDBOTRUNC TDBOTRUNC)
(define TC_TDBONOLCK TDBONOLCK)
(define TC_TDBOLCKNB TDBOLCKNB)

;; tc-tdb-set-index flags

(define-foreign-variable TDBITLEXICAL int "TDBITLEXICAL")
(define-foreign-variable TDBITDECIMAL int "TDBITDECIMAL")
;; (define-foreign-variable TDBITTOKEN int "TDBITTOKEN")
;; (define-foreign-variable TDBITQGRAM int "TDBITQGRAM")
(define-foreign-variable TDBITOPT int "TDBITOPT")
(define-foreign-variable TDBITVOID int "TDBITVOID")
(define-foreign-variable TDBITKEEP int "TDBITKEEP")

(define TC_TDBITLEXICAL TDBITLEXICAL)
(define TC_TDBITDECIMAL TDBITDECIMAL)
;; (define TC_TDBITTOKEN TDBITTOKEN)
;; (define TC_TDBITQGRAM TDBITQGRAM)
(define TC_TDBITOPT TDBITOPT)
(define TC_TDBITVOID TDBITVOID)
(define TC_TDBITKEEP TDBITKEEP)

;; tc-tdb-qry-add-cond flags

(define-foreign-variable TDBQCSTREQ int "TDBQCSTREQ")
(define-foreign-variable TDBQCSTRINC int "TDBQCSTRINC")
(define-foreign-variable TDBQCSTRBW int "TDBQCSTRBW")
(define-foreign-variable TDBQCSTREW int "TDBQCSTREW")
(define-foreign-variable TDBQCSTRAND int "TDBQCSTRAND")
(define-foreign-variable TDBQCSTROR int "TDBQCSTROR")
(define-foreign-variable TDBQCSTROREQ int "TDBQCSTROREQ")
(define-foreign-variable TDBQCSTRRX int "TDBQCSTRRX")
(define-foreign-variable TDBQCNUMEQ int "TDBQCNUMEQ")
(define-foreign-variable TDBQCNUMGT int "TDBQCNUMGT")
(define-foreign-variable TDBQCNUMGE int "TDBQCNUMGE")
(define-foreign-variable TDBQCNUMLT int "TDBQCNUMLT")
(define-foreign-variable TDBQCNUMLE int "TDBQCNUMLE")
(define-foreign-variable TDBQCNUMBT int "TDBQCNUMBT")
(define-foreign-variable TDBQCNUMOREQ int "TDBQCNUMOREQ")
;; (define-foreign-variable TDBQCFTSPH int "TDBQCFTSPH")
;; (define-foreign-variable TDBQCFTSAND int "TDBQCFTSAND")
;; (define-foreign-variable TDBQCFTSOR int "TDBQCFTSOR")
;; (define-foreign-variable TDBQCFTSEX int "TDBQCFTSEX")
(define-foreign-variable TDBQCNEGATE int "TDBQCNEGATE")
(define-foreign-variable TDBQCNOIDX int "TDBQCNOIDX")

(define TC_TDBQCSTREQ TDBQCSTREQ)
(define TC_TDBQCSTRINC TDBQCSTRINC)
(define TC_TDBQCSTRBW TDBQCSTRBW)
(define TC_TDBQCSTREW TDBQCSTREW)
(define TC_TDBQCSTRAND TDBQCSTRAND)
(define TC_TDBQCSTROR TDBQCSTROR)
(define TC_TDBQCSTROREQ TDBQCSTROREQ)
(define TC_TDBQCSTRRX TDBQCSTRRX)
(define TC_TDBQCNUMEQ TDBQCNUMEQ)
(define TC_TDBQCNUMGT TDBQCNUMGT)
(define TC_TDBQCNUMGE TDBQCNUMGE)
(define TC_TDBQCNUMLT TDBQCNUMLT)
(define TC_TDBQCNUMLE TDBQCNUMLE)
(define TC_TDBQCNUMBT TDBQCNUMBT)
(define TC_TDBQCNUMOREQ TDBQCNUMOREQ)
;; (define TC_TDBQCFTSPH TDBQCFTSPH)
;; (define TC_TDBQCFTSAND TDBQCFTSAND)
;; (define TC_TDBQCFTSOR TDBQCFTSOR)
;; (define TC_TDBQCFTSEX TDBQCFTSEX)
(define TC_TDBQCNEGATE TDBQCNEGATE)
(define TC_TDBQCNOIDX TDBQCNOIDX)

;; tc-tdb-qry-set-order flags

(define-foreign-variable TDBQOSTRASC int "TDBQOSTRASC")
(define-foreign-variable TDBQOSTRDESC int "TDBQOSTRDESC")
(define-foreign-variable TDBQONUMASC int "TDBQONUMASC")
(define-foreign-variable TDBQONUMDESC int "TDBQONUMDESC")

(define TC_TDBQOSTRASC TDBQOSTRASC)
(define TC_TDBQOSTRDESC TDBQOSTRDESC)
(define TC_TDBQONUMASC TDBQONUMASC)
(define TC_TDBQONUMDESC TDBQONUMDESC)

(define-record tc-tdb ptr path)
(define-record-printer (tc-tdb tdb port)
  (fprintf port "#<tc-tdb ~A on ~S>"
           (or (tc-tdb-ptr tdb) "(closed)")
           (tc-tdb-path tdb)))

(define-foreign-type tdb
  (nonnull-c-pointer "TCTDB")
  ; tc-tdb-ptr
  )

(define-record tc-tdb-qry ptr)

(define-foreign-type tc-tdb-qry
  (nonnull-c-pointer "TDBQRY")
  ; tc-tdb-qry-ptr
  )

#>? #include "tctdbapi.h" <#

(define (tc-tdb-open file
                     #!key
                     (flags (fx+ TDBOWRITER (fx+ TDBOREADER TDBOCREAT)))
                     (mutex? #f)
                     (num-buckets #f)
                     (record-alignment #f)
                     (num-free-blocks #f)
                     (tune-opts #f)
                     (cache-limit #f)
                     (leaf-cache #f)
                     (non-leaf-cache #f)
                     (mmap-size #f))
  (let ((tdb (make-tc-tdb (%tc-tdb-new) file)))
    (and (tc-tdb-ptr tdb)
         ;; make sure all the specified keyword settings succeed, and
         ;; return the tdb record
         (or (and
              (or (not mutex?) (%tc-tdb-setmutex tdb))
              (or (not (or cache-limit leaf-cache non-leaf-cache))
                  (%tc-tdb-setcache tdb
                                    (or cache-limit 0)
                                    (or leaf-cache 0)
                                    (or non-leaf-cache 0)))
              (or (not mmap-size) (%tc-tdb-setxmsiz tdb mmap-size))
              (or (not (or num-buckets record-alignment num-free-blocks
                           tune-opts))
                  (%tc-tdb-tune tdb
                                (or num-buckets 0)
                                (or record-alignment -1)
                                (or num-free-blocks -1)
                                (or tune-opts 0)))
              (%tc-tdb-open tdb file flags)
              tdb)
             (begin
               ;; clean up and return #f if any of the functions failed
               (%tc-tdb-del tdb)
               #f)))))

(define (tc-tdb-close tdb)
  (and (%tc-tdb-close tdb)
       (begin (%tc-tdb-del tdb)
              (tc-tdb-ptr-set! tdb #f) ; prevent further use
              #t)))

(define (tc-tdb-put! tdb key tscstr) ; tab separated column string
  (%tc-tdb-put3 tdb key tscstr))

(define (tc-tdb-put-tc-map! tdb key tc-map)
  (%tc-tdb-put tdb key (string-length key) tc-map))

(define (tc-tdb-out! tdb key)
  (%tc-tdb-out tdb key (string-length key)))

;; delete tc-map when finished
(define (tc-tdb-get tdb key)
  (let ((tc-map (make-tc-map (%tc-tdb-get tdb key (string-length key)))))
    (and (tc-map-ptr tc-map)
         tc-map)))

(define tc-tdb-iter-init %tc-tdb-iterinit)
(define (tc-tdb-iter-next tdb)
  (let-location ((size int))
    (and-let* ((ptr (%tc-tdb-iternext tdb (location size))))
      (sized-c-string* ptr size 'tc-tdb-iter-next))))

(define (tc-tdb-fold tdb kons knil)
  (tc-tdb-iter-init tdb)
  (let lp ((acc knil))
    (let ((key (tc-tdb-iter-next tdb)))
      (if (not key)
          acc
          (let ((val (tc-tdb-get tdb key)))
            (lp (kons key val acc)))))))

(define tc-tdb-sync %tc-tdb-sync)
(define tc-tdb-vanish %tc-tdb-vanish)
(define tc-tdb-copy %tc-tdb-copy)
(define tc-tdb-transaction-begin %tc-tdb-tranbegin)
(define tc-tdb-transaction-commit %tc-tdb-trancommit)
(define tc-tdb-transaction-abort %tc-tdb-tranabort)
(define tc-tdb-record-count %tc-tdb-rnum)
(define tc-tdb-file-size %tc-tdb-fsiz)

(define tc-tdb-set-index %tc-tdb-setindex)

(define tc-tdb-gen-uid %tc-tdb-genuid)

(define (tc-tdb-qry-new tdb)
  (make-tc-tdb-qry (%tc-tdb-qry-new tdb)))

(define (tc-tdb-qry-del tc-tdb-qry)
  (begin (%tc-tdb-qry-del tc-tdb-qry)
         (tc-tdb-qry-ptr-set! tc-tdb-qry #f) ; prevent further use
         #t))

(define tc-tdb-qry-add-cond %tc-tdb-qry-addcond)
(define tc-tdb-qry-set-order %tc-tdb-qry-setorder)
(define tc-tdb-qry-set-limit %tc-tdb-qry-setlimit)

;; TODO: delete tc-list when finished
(define (tc-tdb-qry-search tc-tdb-qry)
  (let ((tc-list (make-tc-list (%tc-tdb-qry-search tc-tdb-qry))))
    (and (tc-list-ptr tc-list)
         tc-list)))
         

)
