/*
 * forwarder.c
 * receive all incoming udp packets destined to port 6000 and forwards
 */
#include "config.h"
#include "dsecommon.h"
#include <net/if.h>		/* IFNAMSIZ */
#include <fcntl.h>		/* fcntl() */

/* free and set to NULL */
#define CLEAN(ptr) if (ptr) { free(ptr); ptr = NULL; }

struct ifinfo_struct {
  char name[IFNAMSIZ];
  struct sockaddr_in addr;
};
typedef struct ifinfo_struct my_ifinfo;

static int sockfd;
static short int port;
static short int peerport = PEERPORT;
static my_ifinfo *g_ifinfo;
static int num_ifaces; /* number of active interfaces */

static void dg_forward(int sockfd);
static void update_ifinfo_list(void);
void handle_hup(int signo);
void handle_int(int signo);

int main(int argc, char **argv)
{
  int ret;
  int sockfd;
  const int on = 1;
  struct sockaddr_in servaddr;

  printf("pid = %d\n", (int) getpid());
  fflush(stdout);

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd == -1) {
    perror("socket");
    exit(1);
  }

  memset(&servaddr, 0, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  if (argc > 1) { /* ip address to bind into */
#if defined(_WIN32) || defined(__CYGWIN__)
    if (inet_aton(argv[1], &servaddr.sin_addr) == 0) {
#else
    if (inet_pton(AF_INET, argv[1], &servaddr.sin_addr) <= 0) {
#endif
      fprintf(stderr, "Invalid address : %s\n", argv[1]);
      exit(1);
    }
#ifdef __DEBUG__
    printf("Using address : %s\n", argv[1]);
#endif
  } else {
#ifdef __DEBUG__
    printf("Using wildcard address\n");
#endif
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  }
  if (argc > 2) { /* port supplied */
    port = (short) atoi(argv[2]);
  } else {
    port = BINDPORT;
  }
#ifdef __DEBUG__
  printf("Using port : %d\n", port);
#endif
  servaddr.sin_port = htons(port);

  ret = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
  if (ret < 0) {
    perror("setsockopt");
  }
  /* allow receiving broadcasts (not normally required) */
  ret = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
  if (ret < 0) {
    perror("setsockopt");
  }

  ret = bind(sockfd, (SA *) &servaddr, sizeof(servaddr));
  if (ret == -1) {
    perror("bind");
    close(sockfd);
    exit(2);
  }

#if !defined(_WIN32) && !defined(__CYGWIN__)
  setuid(getuid()); /* we need not be root anymore */
#endif

  signal(SIGHUP, handle_hup);
  signal(SIGINT, handle_int);
  signal(SIGTERM, handle_int);
#ifdef __DEBUG__
  signal(SIGQUIT, handle_hup); /* in debug mode, allow update using Ctrl-\ */
#else
  signal(SIGQUIT, handle_int);
#endif

  dg_forward(sockfd);

  return 0;
}

static void dg_forward(int sockfd)
{
  volatile int n;
  volatile int ret;
  volatile int i;
  char mesg[MAXLINE];
  socklen_t len;
  struct sockaddr_in cliaddr;
  my_ifinfo *temp;

  len = sizeof(cliaddr);
  while (1) {
    n = recvfrom(sockfd, mesg, sizeof(mesg), 0, (SA *) &cliaddr, &len);
    if (n < 0) {
#ifdef __DEBUG__
      perror("recvfrom");
#endif
      continue;
    }
#ifdef __DEBUG__
    fprintf(stderr, "+++%d bytes received from %s:%d\n", n,
	inet_ntoa(cliaddr.sin_addr), ntohs(cliaddr.sin_port));
#endif

    temp = g_ifinfo;
    /* now send the received packet to all the interfaces */
    for (i = 0; i < num_ifaces; i++) {
#ifdef __DEBUG__
      printf("---Sending to %s:%d\n", inet_ntoa(temp->addr.sin_addr),
	  ntohs(temp->addr.sin_port));
#endif
      ret = sendto(sockfd, mesg, n, 0, (SA *) &temp->addr, len);
      if (ret < n) {
	perror("sendto");
      }
#ifdef __DEBUG__
      printf("^^^%d bytes sent\n", ret);
#endif
      temp++;
    }
  }
}

static void update_ifinfo_list(void)
{
  FILE *fp;
  char straddr[20];
  char buf[40];
  int i;
  my_ifinfo *temp;

  CLEAN(g_ifinfo);
  num_ifaces = 0;

  fp = fopen(IFINFOFILE, "r");
  if (!fp)
    return;

  fgets(buf, sizeof(buf), fp);
  num_ifaces = atoi(buf);
  if (num_ifaces <= 0) {
    fclose(fp);
    return;
  }
  temp = g_ifinfo = (my_ifinfo *) calloc(num_ifaces, sizeof(my_ifinfo));
  for (i = 0; i < num_ifaces; i++) {
    fgets(buf, sizeof(buf), fp);
    sscanf(buf, "%s%s", temp->name, straddr);
#if defined(_WIN32) || defined(__CYGWIN__)
    inet_aton(straddr, &temp->addr.sin_addr);
#else
    inet_pton(AF_INET, straddr, &temp->addr.sin_addr);
#endif
//    temp->addr.sin_family = htons(DSESERV_PORT); /* this is the culprit */
    temp->addr.sin_family = AF_INET;
    temp->addr.sin_port = htons(peerport);
    printf("<%s> : <%s>\n", temp->name, straddr);
    temp++;
  }
  fclose(fp);

  /* so that we get the log output immediately */
  fflush(stdout);
  fflush(stderr);

}

void handle_hup(int signo)
{
  update_ifinfo_list();
  return;
}

void handle_int(int signo)
{
#ifdef __DEBUG__
  fprintf(stderr, "Signal <%d> caught. Exiting...\n", signo);
#endif
  CLEAN(g_ifinfo);
  close(sockfd);
  exit(signo);
}
