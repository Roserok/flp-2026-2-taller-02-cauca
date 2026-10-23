#lang eopl
;Autores: Maria Fernanda Betancourt Montoya 2459510, Oliver De Jesus Arboleda Baez 2459684, Kevin Andres Rosero Romo 2459554

;; Taller 2 — El intérprete de Cauca.
;; El TAD ambiente, la búsqueda de ligaduras y el ambiente inicial.
;; Requiere sintaxis.rkt y valores.rkt.
;;
;; Aquí se declara con define-datatype el tipo ambiente, con tres
;; variantes:
;;
;;   ambiente-vacio()
;;   ambiente-extendido(ids, valores, env)
;;     ids      (list-of symbol?)
;;     valores  list?
;;     env      ambiente?
;;   ambiente-recursivo(proc-names, idss, bodies, env)
;;     proc-names  (list-of symbol?)   los nombres declarados en el letrec
;;     idss        list?               la lista de parámetros de cada uno
;;     bodies      (list-of expresion?) los cuerpos, guardados sin evaluar
;;     env         ambiente?
;;
;; La variante recursiva no construye clausuras: las arma apply-env en el
;; momento de la búsqueda, y el ambiente que les entrega es el propio
;; ambiente-recursivo.

(require "sintaxis.rkt")
(require "valores.rkt")

;; ambiente
;; Datatype del ambiente: una cadena de ligaduras que termina en el
;; ambiente vacío.
;;   ambiente-vacio     : -> ambiente
;;   ambiente-extendido : (list-of symbol?) x list? x ambiente? -> ambiente
;;   ambiente-recursivo : (list-of symbol?) x list? x (list-of expresion?)
;;                        x ambiente? -> ambiente
(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss list?)
   (bodies (list-of expresion?))
   (env ambiente?)))

;; buscar-posicion : symbol x (list-of symbol) -> (entero | #f)
;; Retorna la posición (desde 0) de la primera aparición de id en la
;; lista de símbolos, o #f si no aparece.
(define buscar-posicion
  (lambda (id lista)
    (letrec ((buscar
              (lambda (resto pos)
                (cond
                  ((null? resto) #f)
                  ((eqv? (car resto) id) pos)
                  (else (buscar (cdr resto) (+ pos 1)))))))
      (buscar lista 0))))

;; apply-env : ambiente x symbol -> valor
;; Busca el identificador en el ambiente, respetando el shadowing de las
;; ligaduras más recientes, y levanta eopl:error si no está ligado.
;; En un ambiente-recursivo, si el nombre es de un procedimiento del
;; letrec, construye la cerradura en ese momento y le entrega como
;; ambiente el propio ambiente-recursivo
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "Variable no ligada: " id))
      (ambiente-extendido (ids valores amb-padre)
        (let ((pos (buscar-posicion id ids)))
          (if pos
              (list-ref valores pos)
              (apply-env amb-padre id))))
      (ambiente-recursivo (proc-names idss bodies amb-padre)
        (let ((pos (buscar-posicion id proc-names)))
          (if pos
              (cerradura (list-ref idss pos) (list-ref bodies pos) env)
              (apply-env amb-padre id)))))))

;; ambiente-inicial : -> ambiente
;; El ambiente con que arranca todo programa:
;; n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r)
                        '(10 3 7 2 5)
                        (ambiente-vacio))))

(provide (all-defined-out))