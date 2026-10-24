#lang eopl
;Autores: Maria Fernanda Betancourt Montoya 2459510, Oliver De Jesus Arboleda Baez 2459684, Kevin Andres Rosero Romo 2459554


;; Taller 2 — El intérprete de Cauca.
;; Las primitivas del lenguaje y las verificaciones de tipo y de
;; cantidad de argumentos que cada una exige. Requiere sintaxis.rkt.
;;
;; Aridades: +, -, *, / son n-arias; add1, sub1, not y abs son unarias;
;; las relacionales, and, or, xor e implica son binarias; entre es
;; ternaria; mcd y mcm son n-arias sobre enteros con al menos dos
;; argumentos; promedio es n-aria sobre números con al menos uno.

(require "sintaxis.rkt")

;; exigir-numeros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son números; si no, levanta
;; eopl:error a nombre de quien hizo la verificación.
(define exigir-numeros
  (lambda (args quien)
    (if (null? args)
        #t
        (if (number? (car args))
            (exigir-numeros (cdr args) quien)
            (eopl:error quien "Se esperaban numeros: ~s" args)))))

;; exigir-enteros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son enteros; si no, levanta error.
(define exigir-enteros
  (lambda (args quien)
    (if (null? args)
        #t
        (if (integer? (car args))
            (exigir-enteros (cdr args) quien)
            (eopl:error quien "Se esperaban enteros: ~s" args)))))

;; exigir-booleanos : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son booleanos; si no, levanta error.
(define exigir-booleanos
  (lambda (args quien)
    (if (null? args)
        #t
        (if (boolean? (car args))
            (exigir-booleanos (cdr args) quien)
            (eopl:error quien "Se esperaban booleanos: ~s" args)))))

;; exigir-cantidad : lista x int x symbol -> boolean
;; Retorna #t si llegaron exactamente n argumentos; si no, levanta error.
(define exigir-cantidad
  (lambda (args n quien)
    (if (= (length args) n)
        #t
        (eopl:error quien "Se esperaban ~s argumentos, llegaron ~s"
                    n
                    (length args)))))

;; exigir-minimo : lista x int x symbol -> boolean
;; Retorna #t si llegaron al menos n argumentos; si no, levanta error.
(define exigir-minimo
  (lambda (args n quien)
    (if (>= (length args) n)
        #t
        (eopl:error quien "Se esperaban al menos ~s argumentos, llegaron ~s"
                    n
                    (length args)))))

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Verifica la cantidad y el tipo de los argumentos y aplica la
;; primitiva. Se resuelve con cases sobre el datatype primitiva.
(define evaluar-primitiva
  (lambda (prim args)
    (letrec ((valor-absoluto
              (lambda (n)
                (if (< n 0) (- 0 n) n)))
             (mcd-dos
              (lambda (a b)
                (if (= b 0)
                    (valor-absoluto a)
                    (mcd-dos b (remainder a b)))))
             (mcm-dos
              (lambda (a b)
                (if (or (= a 0) (= b 0))
                    0
                    (/ (* (valor-absoluto a) (valor-absoluto b))
                       (mcd-dos a b)))))
             (reducir
              (lambda (operacion acumulado resto)
                (if (null? resto)
                    acumulado
                    (reducir operacion
                             (operacion acumulado (car resto))
                             (cdr resto))))))
      (cases primitiva prim
        (sum-prim ()
          (exigir-numeros args 'sum-prim)
          (apply + args))
        (minus-prim ()
          (exigir-numeros args 'minus-prim)
          (apply - args))
        (mult-prim ()
          (exigir-numeros args 'mult-prim)
          (apply * args))
        (div-prim ()
          (exigir-numeros args 'div-prim)
          (apply / args))
        (add-prim ()
          (exigir-cantidad args 1 'add-prim)
          (exigir-numeros args 'add-prim)
          (+ (car args) 1))
        (sub-prim ()
          (exigir-cantidad args 1 'sub-prim)
          (exigir-numeros args 'sub-prim)
          (- (car args) 1))
        (mayor-prim ()
          (exigir-cantidad args 2 'mayor-prim)
          (exigir-numeros args 'mayor-prim)
          (> (car args) (cadr args)))
        (mayorigual-prim ()
          (exigir-cantidad args 2 'mayorigual-prim)
          (exigir-numeros args 'mayorigual-prim)
          (>= (car args) (cadr args)))
        (menor-prim ()
          (exigir-cantidad args 2 'menor-prim)
          (exigir-numeros args 'menor-prim)
          (< (car args) (cadr args)))
        (menorigual-prim ()
          (exigir-cantidad args 2 'menorigual-prim)
          (exigir-numeros args 'menorigual-prim)
          (<= (car args) (cadr args)))
        (igual-prim ()
          (exigir-cantidad args 2 'igual-prim)
          (exigir-numeros args 'igual-prim)
          (= (car args) (cadr args)))
        (not-prim ()
          (exigir-cantidad args 1 'not-prim)
          (exigir-booleanos args 'not-prim)
          (not (car args)))
        (and-prim ()
          (exigir-cantidad args 2 'and-prim)
          (exigir-booleanos args 'and-prim)
          (and (car args) (cadr args)))
        (or-prim ()
          (exigir-cantidad args 2 'or-prim)
          (exigir-booleanos args 'or-prim)
          (or (car args) (cadr args)))
        (abs-prim ()
          (exigir-cantidad args 1 'abs-prim)
          (exigir-numeros args 'abs-prim)
          (valor-absoluto (car args)))
        (mcd-prim ()
          (exigir-minimo args 2 'mcd-prim)
          (exigir-enteros args 'mcd-prim)
          (reducir mcd-dos (car args) (cdr args)))
        (mcm-prim ()
          (exigir-minimo args 2 'mcm-prim)
          (exigir-enteros args 'mcm-prim)
          (reducir mcm-dos (car args) (cdr args)))
        (promedio-prim ()
          (exigir-minimo args 1 'promedio-prim)
          (exigir-numeros args 'promedio-prim)
          (/ (apply + args) (length args)))
        (xor-prim ()
          (exigir-cantidad args 2 'xor-prim)
          (exigir-booleanos args 'xor-prim)
          (not (eqv? (car args) (cadr args))))
        (implica-prim ()
          (exigir-cantidad args 2 'implica-prim)
          (exigir-booleanos args 'implica-prim)
          (or (not (car args)) (cadr args)))
        (entre-prim ()
          (exigir-cantidad args 3 'entre-prim)
          (exigir-numeros args 'entre-prim)
          (and (<= (cadr args) (car args))
               (<= (car args) (caddr args))))))))

(provide (all-defined-out))
