#lang eopl
;Autores: Maria Fernanda Betancourt Montoya 2459510, Oliver De Jesus Arboleda Baez 2459684, Kevin Andres Rosero Romo 2459554

;; Taller 2 — El intérprete de Cauca.
;; Fachada: reúne los seis módulos de src/ y reexporta todo lo que
;; definen, de modo que quien la requiera vea todos los nombres sin
;; requerir los módulos uno por uno.
;;
;;   src/sintaxis.rkt    especificación léxica y gramatical, scanner, parser
;;   src/valores.rkt     el valor procedimiento
;;   src/ambiente.rkt    el TAD ambiente y el ambiente inicial
;;   src/primitivas.rkt  las primitivas y sus verificaciones
;;   src/interprete.rkt  la evaluación y la aplicación de procedimientos
;;   src/interfaz.rkt    el punto de entrada y el REPL
;;
;; Los require van en un solo sentido. Racket no carga dos módulos que se
;; requieran entre sí.

(require "src/sintaxis.rkt")
(require "src/valores.rkt")
(require "src/ambiente.rkt")
(require "src/primitivas.rkt")
(require "src/interprete.rkt")
(require "src/interfaz.rkt")

(provide (all-from-out "src/sintaxis.rkt"
                       "src/valores.rkt"
                       "src/ambiente.rkt"
                       "src/primitivas.rkt"
                       "src/interprete.rkt"
                       "src/interfaz.rkt"))

;;; ==========================================================
;;; Ejemplos
;;; ==========================================================

#|
  Aquí van los ejemplos que pide el enunciado: 5 del scanner, 5 del
  parser y los de ejecución de cada parte, con el resultado de cada uno
  escrito al lado. Las pruebas con rackunit viven en pruebas-cauca.rkt.

  Scanner
    (scanner "42")
      => un token numero con el valor 42
    (scanner "-3.5")
      => un token numero con el flotante negativo -3.5
    (scanner "suma_1?")
      => un token identificador con el símbolo suma_1?
    (scanner "// comentario\n+(1, 2)")
      => ignora el comentario y reconoce +, (, 1, ",", 2 y )
    (scanner "if true then n else m end")
      => palabras reservadas if, true, then, else, end e identificadores n y m

  Parser
    (parser "42")
      => a-program con lit-exp(42)
    (parser "n")
      => a-program con var-exp(n)
    (parser "+(1, 2)")
      => a-program con prim-exp(sum-prim, [lit-exp(1), lit-exp(2)])
    (parser "if true then 1 else 2 end")
      => a-program con if-exp(true-exp, lit-exp(1), lit-exp(2))
    (parser "let x = 2 in +(x, 3) end")
      => a-program con let-exp([x], [lit-exp(2)], prim-exp(sum-prim, ...))

  Ejecución del lenguaje base
    (interpretar "+(1, 2, 3)")
      => 6
    (interpretar "-(10, 3, 2)")
      => 5
    (interpretar "*(2, 3, 4)")
      => 24
    (interpretar "/(100, 5, 2)")
      => 10
    (interpretar "+(add1(n), sub1(m))")
      => 13
    (interpretar "and(>(n, m), >=(p, r))")
      => #t
    (interpretar "or(<(q, r), <=(r, q))")
      => #t
    (interpretar "==(n, 10)")
      => #t
    (interpretar "not(false)")
      => #t
    (interpretar "let x = 2 y = 3 in if >(y, x) then *(x, y) else 0 end end")
      => 6
    (interpretar "if 1 then 2 else 3 end")
      => error: la condición de if debe ser booleana
    (interpretar "z")
      => error: variable no ligada

  Primitivas nuevas
    (interpretar "abs(-7)")               => 7
    (interpretar "abs(7)")                => 7
    (interpretar "abs(-3.5)")             => 3.5
    (interpretar "abs(true)")             => error: se esperaban números

    (interpretar "mcd(12, 18)")           => 6
    (interpretar "mcd(7, 13)")            => 1
    (interpretar "mcd(12, 18, 24)")       => 6
    (interpretar "mcd(1.5, 2)")           => error: se esperaban enteros

    (interpretar "mcm(4, 6)")             => 12
    (interpretar "mcm(3, 5)")             => 15
    (interpretar "mcm(2, 3, 4)")          => 12
    (interpretar "mcm(4)")                => error: se esperaban al menos 2 argumentos

    (interpretar "promedio(1, 2, 3, 4)")  => 5/2
    (interpretar "promedio(10)")          => 10
    (interpretar "promedio(n, m)")        => 13/2
    (interpretar "promedio()")            => error: se esperaba al menos 1 argumento

    (interpretar "xor(true, false)")      => #t
    (interpretar "xor(true, true)")       => #f
    (interpretar "xor(false, false)")     => #f
    (interpretar "xor(1, true)")          => error: se esperaban booleanos

    (interpretar "implica(true, false)")  => #f
    (interpretar "implica(false, false)") => #t
    (interpretar "implica(true, true)")   => #t
    (interpretar "implica(true)")         => error: se esperaban 2 argumentos

    (interpretar "entre(5, 1, 10)")       => #t
    (interpretar "entre(1, 1, 10)")       => #t
    (interpretar "entre(11, 1, 10)")      => #f
    (interpretar "entre(true, 1, 10)")    => error: se esperaban números

  Procedimientos
    (interpretar "let f = proc () 7 end in apply f () end")
      => 7
    (interpretar "let doble = proc (x) *(x, 2) end in apply doble (21) end")
      => 42
    (interpretar "let f = proc (a, b, c) +(a, b, c) end in apply f (1, 2, 3) end")
      => 6
    (interpretar "let aplicar = proc (f, x) apply f (x) end doble = proc (v) *(v, 2) end in apply aplicar (doble, 5) end")
      => 10
    (interpretar "let fabrica = proc (a) proc (b) +(a, b) end end in let suma3 = apply fabrica (3) in apply suma3 (4) end end")
      => 7
    (interpretar "let factor = 10 in let escalar = proc (v) *(v, factor) end in let factor = 1000 in apply escalar (5) end end end")
      => 50
    (interpretar "apply 5 (1)")
      => error: el operador no es un procedimiento
    (interpretar "let f = proc (a, b) +(a, b) end in apply f (1) end")
      => error: cantidad de argumentos incorrecta

  Recursión y case
    (interpretar "letrec factorial (x) = if ==(x, 0) then 1 else *(x, apply factorial (sub1(x))) end in apply factorial (5) end")
      => 120
    (interpretar "letrec potencia (base, exp) = if ==(exp, 0) then 1 else *(base, apply potencia (base, sub1(exp))) end in apply potencia (2, 10) end")
      => 1024
    (interpretar "letrec par? (x) = if ==(x, 0) then true else apply impar? (sub1(x)) end impar? (x) = if ==(x, 0) then false else apply par? (sub1(x)) end in apply par? (10) end")
      => #t
    (interpretar "letrec aplicarn (f, x, veces) = if ==(veces, 0) then x else apply f (apply aplicarn (f, x, sub1(veces))) end in let doble = proc (v) *(v, 2) end in apply aplicarn (doble, 1, 5) end end")
      => 32

    (interpretar "case 3 of 1 => 100 of 3 => 300 otherwise => 0 end")
      => 300
    (interpretar "case 5 of 1 => 100 of 3 => 300 otherwise => 0 end")
      => 0
    (interpretar "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end")
      => 30
    (interpretar "case true of 1 => 1 otherwise => 0 end")
      => error: la expresión de control de case debe ser numérica
|#