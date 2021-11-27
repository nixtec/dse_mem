/*
 * receiver.c
 * receive all incoming udp packets destined to port 6000
 */
#include "config.h"
#include "dsecommon.h"

static void dg_echo(int sockfd, SA *pcliaddr, socklen_t clilen);

int main(int argc, char **argv)
{
  int ret;
  int sockfd;
  struct sockaddr_in servaddr, cliaddr;

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
  } else {
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  }
  if (argc > 2) { /* port supplied */
    servaddr.sin_port = htons(atoi(argv[2]));
  } else {
    servaddr.sin_port = htons(BINDPORT);
  }

  switch (argc) {
    case 1:
      printf("Binding to *:%d\n", BINDPORT);
      break;
    case 2:
      printf("Binding to %s:%d\n", argv[1], BINDPORT);
      break;
    case 3:
      printf("Binding to %s:%s\n", argv[1], argv[2]);
      break;
    default:
      fprintf(stderr, "Usage: %s [ipaddress [port]]\n", argv[0]);
      exit(1);
      break;
  }

  ret = bind(sockfd, (SA *) &servaddr, sizeof(servaddr));
  if (ret == -1) {
    perror("bind");
    close(sockfd);
    exit(2);
  }

  dg_echo(sockfd, (SA *) &cliaddr, sizeof(cliaddr));

  return 0;
}

static void dg_echo(int sockfd, SA *pcliaddr, socklen_t clilen)
{
  struct sockaddr_in *psaddr;

  int n;
  socklen_t len;
  char mesg[MAXLINE];

  psaddr = (struct sockaddr_in *) pcliaddr;

  while (1) {
    len = clilen;
    n = recvfrom(sockfd, mesg, MAXLINE, 0, pcliaddr, &len);
    fprintf(stderr, "+++%d bytes received from %s:%d\n", n,
       	inet_ntoa(psaddr->sin_addr), (int) ntohs(psaddr->sin_port));
    fflush(stderr);
    fflush(stdout);
//    write(1, mesg, n);
//    sendto(sockfd, mesg, n, 0, pcliaddr, len);
  }
}
