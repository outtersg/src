// http://rachid.koucha.free.fr/tech_corner/pty_pdip_fr.html
// Permet d'enrober un psql (ou un pg_dump, en lur balançant < /dev/null pour qu'il n'attende pas éternellement une entrée) pour que la saisie de mot de passe se fasse automatiquement depuis le programme, plutôt que de requérir une saisie dans le terminal.
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#define __USE_BSD
#include <termios.h>
#include <sys/select.h>
#include <sys/ioctl.h>
#include <string.h>

#define TRACE if(0) fprintf

int attends(int f, char ** attentes)
{
    int t2;
    char bloc[0x1000];
    char ** attente;
    int t = 0;
    while(1)
    {
        switch(t2 = read(f, &bloc[t], 1)) // Pour le moment octet par octet: on ne veut pas en lire trop; on optimisera plus tard.
        {
            case 0:
            case -1:
                return -1;
        }

        t += t2;
        bloc[t] = 0;

        for(attente = attentes; *attente; ++attente)
        if(strstr(bloc, *attente))
        {
            fprintf(stdout, bloc);
            fflush(stdout);
            TRACE(stderr, "trouve\n");
            return 0;
        }
    }
}

#define TBLOC 0x1000

int maitre(int fdm, int tube)
{
    int e = 0;
    char * attentes[2];
    attentes[0] = "Password: ";
    attentes[1] = NULL;

    attends(fdm, attentes);
    usleep(300000);
    write(fdm, "password\n", 9);

    char blocs[2][TBLOC];
    int restes[2];
    int fmax;
    char * pBlocs[2];
    int  rc;
  fd_set fd_in;
    fd_set etatsS;
    restes[0] = 0;
    restes[1] = 0;
    pBlocs[0] = &blocs[0][0];
    pBlocs[1] = &blocs[1][0];
    // Code du processus pere
    // Fermeture de la partie esclave du PTY
    while (fdm >= 0)
    {
        fmax = -1;
      TRACE(stderr, "-> (Attente de mouvement)\n");
      // Attente de données de l'entrée standard et du PTY maître
      FD_ZERO(&fd_in);
      if(e >= 0 && restes[0] < TBLOC) { FD_SET(e, &fd_in); if(fmax < e) fmax = e; TRACE(stderr, "attends données sur stdin\n");}
      if(fdm >= 0 && restes[1] < TBLOC) { FD_SET(fdm, &fd_in); if(fmax < fdm) fmax = fdm; TRACE(stderr, "attends données du fils\n");}
      FD_ZERO(&etatsS);
      if(restes[0]) { FD_SET(tube, &etatsS); if(fmax < tube) fmax = tube; TRACE(stderr, "attends place chez fils\n"); }
      if(restes[1]) { FD_SET(1, &etatsS); if(fmax < 1) fmax = 1; TRACE(stderr, "attends place sur stdout\n"); }
      rc = select(fmax + 1, &fd_in, &etatsS, NULL, NULL);
      switch(rc)
      {
        case -1 : fprintf(stderr, "Erreur %d sur select()\n", errno);
                  exit(1);
        default :
        {
          if (FD_ISSET(tube, &etatsS))
          {
                if((rc = write(tube, pBlocs[0], restes[0])) > 0)
                {
                    if((restes[0] -= rc) <= 0)
                        pBlocs[0] = &blocs[0][0];
                    else
                        pBlocs[0] += rc;
                    TRACE(stderr, "   Transmis: %d\n", rc);
                }
                if(e < 0 && !restes[0])
                    close(tube);
          }
          // S'il y a des donnees sur le PTY maitre
          if (FD_ISSET(1, &etatsS))
          {
                if((rc = write(1, pBlocs[1], restes[1])) > 0)
                {
                    if((restes[1] -= rc) <= 0)
                        pBlocs[1] = &blocs[1][0];
                    else
                        pBlocs[1] += rc;
                    TRACE(stderr, "   Transmis: %d\n", rc);
                }
          }
          // S'il y a des donnees sur l'entree standard
          if (FD_ISSET(0, &fd_in))
          {
            switch(rc = read(0, pBlocs[0] + restes[0], &blocs[0][TBLOC] - (pBlocs[0] + restes[0])))
            {
                case -1:
                    fprintf(stderr, "Erreur %d sur read entree standard\n", errno);
                case 0:
                  TRACE(stderr, "-> Fermeture de stdin: %d\n", rc);
                    close(0);
                    e = -1;
					if(!restes[0])
						close(tube);
                    break;
                default:
                  TRACE(stderr, "-> Lecture sur stdin: %d\n", rc);
                  restes[0] += rc;
            }
          }
          // S'il y a des donnees sur le PTY maitre
          if (FD_ISSET(fdm, &fd_in))
          {
            switch(rc = read(fdm, pBlocs[1] + restes[1], &blocs[1][TBLOC] - (pBlocs[1] + restes[1])))
            {
                case -1:
                    fprintf(stderr, "Erreur %d sur read PTY maitre\n", errno);
                case 0:
                  TRACE(stderr, "-> Fermeture du tube: %d\n", rc);
                    close(fdm);
                    fdm = -1;
                    break;
                default:
                  TRACE(stderr, "-> Lecture sur tube: %d %02.2x\n", rc, *(char *)(pBlocs[1] + restes[1]));
                  restes[1] += rc;
                break;
                }
          }
        }
      } // End switch
    } // End while
      TRACE(stderr, "-> (Fini)\n");
}

int main(int argc, char *argv[])
{
    int  fdm, fds;
    int  rc;
    if((fdm = posix_openpt(O_RDWR)) < 0) { fprintf(stderr, "Erreur %d sur posix_openpt()\n", errno); return 1; }
    if((rc = grantpt(fdm)) < 0) { fprintf(stderr, "Erreur %d sur grantpt()\n", errno); return 1; }
    if((rc = unlockpt(fdm)) < 0) { fprintf(stderr, "Erreur %d sur unlockpt()\n", errno); return 1; }
  // Ouverture du PTY esclave
  fds = open(ptsname(fdm), O_RDWR);
  int tube[2]; // Pour faire suivre le stdin au sous-process.
  if((rc = pipe(&tube[0])) < 0) { fprintf(stderr, "Erreur %d sur pipe()\n", errno); return 1; }
  // Création d'un processus fils
  if (fork())
  {
    close(tube[0]);
    close(fds);
    maitre(fdm, tube[1]);
  }
  else
  {
    close(tube[1]);
  struct termios slave_orig_term_settings; // Saved terminal settings
  struct termios new_term_settings; // Current terminal settings
    // Code du processus fils
    // Fermeture de la partie maitre du PTY
    close(fdm);
    // Sauvegarde des parametre par defaut du PTY esclave
    rc = tcgetattr(fds, &slave_orig_term_settings);
    // Positionnement du PTY esclave en mode RAW
    new_term_settings = slave_orig_term_settings;
    cfmakeraw (&new_term_settings);
    tcsetattr (fds, TCSANOW, &new_term_settings);
    // Le cote esclave du PTY devient l'entree et les sorties standards du fils
    close(0);
    close(1);
    close(2);
    dup(fds);
    dup(fds);
    dup(fds);
    // Maintenant le descripteur de fichier original n'est plus utile
    close(fds);

    // Le process courant devient un leader de session
    setsid();
    // Comme le process courant est un leader de session, La partie esclave du PTY devient sont terminal de contrôle
    // (Obligatoire pour les programmes comme le shell pour faire en sorte qu'ils gerent correctement leurs sorties)
    ioctl(0, TIOCSCTTY, 1);

    // Execution du programme
    close(0);
    dup(tube[0]);
                    execvp(argv[1], &argv[1]);
  }
  return 0;
}
