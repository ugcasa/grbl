#include <stdio.h>
#include <stdlib.h>

int e1();
int e2();
int e3();
int e4();

// funktiolinko
int main(int argc, char *argv[]) {
    
    int funktio = 0;
    int palaute = 0;
    
    if (argc > 1) funktio = atoi(argv[1]);
    
    printf("\ngrbl \n\n");
    
   // Funktiopointteritaulukko: kaikki palauttavat int ja ottavat ei parametreja
    int (*modulit[])(void) = {
        e1,
        e2,
        e3,
        e4
    };

    palaute = modulit[funktio]();
    printf("[DEBUG] Funktio palautti: %d\n", palaute);
}

int e1() {
// testi 1 
    printf("\nExercise 1 \n\n");
    return 1;
}

int e2() {
// testi 2 
    printf("\nExercise 2 \n\n");
    return 2;
}

int e3() {
// testi 3 
    printf("\nExercise 3 \n\n");
    return 3;
}

int e4() {
// testi 4 
    printf("\nExercise 4 \n\n");
    return 4;
}

    // Vai klassinen: 
    // switch ( function ) {
    //     case 1:
    //         e1();
    //         break;
    //     case 2: 
    //         e2();
    //         break;
    //     case 3:     
    //         e3();
    //         break;
    //     case 4: 
    //         e4();
    //         break;

    //     default:
    //             e1();
    //             e2();
    //             e3();
    //             e4(); 
    //         break;
    // }