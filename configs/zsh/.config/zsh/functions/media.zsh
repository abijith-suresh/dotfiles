# Media helpers

webm2mp4() {
  local input_file="$1"
  local output_file="${input_file%.webm}.mp4"

  ffmpeg -i "$input_file" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output_file"
}
