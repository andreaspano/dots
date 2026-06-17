speed() {
  local host="${1:-8.8.8.8}"
  local width="${2:-30}"
  local height="${3:-60}"

  printf '\033[?25l'
  trap 'printf "\033[?25h\033[0m\n"' RETURN

  ping "$host" | stdbuf -oL awk -v W="$width" -v H="$height" -v HOST="$host" '
function clamp(x,a,b){ return (x<a)?a:((x>b)?b:x) }
function barlen(val, minv, maxv){
  if (maxv<=minv) return 1
  return clamp(int((val - minv) * (W-1) / (maxv - minv) + 1 + 0.5), 1, W)
}
function rep(ch, n,   s){
  s="";
  for(i=1;i<=n;i++) s=s ch;
  return s
}
function make_line(len, label,   s){
  s = rep(".", len)
  if (len < W) s = s rep(" ", W-len)
  return s "  " label
}
function print_screen(   i){
  printf "\033[H\033[J"
  printf "Ping: %s\n\n", HOST

  for (i=r+1; i<=H; i++)
    print lines[i]=="" ? rep(" ", W) : lines[i]

  for (i=1; i<=r; i++)
    print lines[i]=="" ? rep(" ", W) : lines[i]

  printf("\nL: %.2f ms   min: %.2f   max: %.2f   samples: %d\n",
         lastv, winmin, winmax, n)
  fflush()
}

BEGIN{
  r=0;
  n=0;
  printf "\033[H\033[J"
}

/time=/ {
  split($0, a, "time=");
  split(a[2], b, " ");
  v = b[1]+0;
  lastv = v;

  vals[++n] = v;

  if (n > H) {
    for (i=2; i<=n; i++) vals[i-1] = vals[i];
    n = H;
  }

  winmin = vals[1];
  winmax = vals[1];

  for (i=1; i<=n; i++) {
    if (vals[i] < winmin) winmin = vals[i];
    if (vals[i] > winmax) winmax = vals[i];
  }

  if (winmax == winmin) winmax = winmin + 1;

  L = barlen(v, winmin, winmax);
  label = sprintf("%.2f ms", v);

  r = (r % H) + 1;
  lines[r] = make_line(L, label);

  print_screen();
}
'
}
