#lang eopl
;Autores: Maria Fernanda Betancourt Montoya 2459510, Oliver De Jesus Arboleda Baez 2459684, Kevin Andres Rosero Romo 2459554

;; Taller 2 — El intérprete de Cauca.
;; El valor procedimiento. Requiere sintaxis.rkt.
;;
;; Aquí se declara con define-datatype el tipo procval, con un solo
;; constructor:
;;
;;   cerradura(ids, body, env)
;;     ids   (list-of symbol?)  los parámetros del procedimiento
;;     body  expresion?         el cuerpo, guardado sin evaluar
;;     env                      el ambiente vigente donde se definió
;;
;; El campo env se declara con un predicado que acepta cualquier valor,
;; (env (lambda (v) #t)). Exigir ambiente? obligaría a requerir
;; ambiente.rkt desde aquí, y ambiente.rkt ya requiere este módulo para
;; construir clausuras al resolver letrec: Racket no carga dos módulos
;; que se requieran entre sí, levanta cycle in loading. Es el único
;; campo que queda sin verificar.

(require "sintaxis.rkt")

;; procval
;; Datatype del valor procedimiento. Una cerradura guarda los parámetros,
;; el cuerpo sin evaluar y el ambiente de la definición, de modo que al
;; invocarla el cuerpo se evalúe en el ambiente donde nació y no en el de
;; la llamada.
;;   procval?  : any -> boolean
;;   cerradura : (list-of symbol?) x expresion? x any -> procval
(define-datatype procval procval?
  (cerradura
   (ids (list-of symbol?))
   (body expresion?)
   (env (lambda (v) #t))))

(provide (all-defined-out))
