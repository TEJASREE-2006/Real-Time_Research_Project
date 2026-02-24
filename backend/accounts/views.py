# accounts/views.py
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import RegisterSerializer, LoginSerializer
from django.http import JsonResponse, HttpResponseBadRequest
from django.conf import settings
from gtts import gTTS
from django.views.decorators.csrf import csrf_exempt
import logging
import os
import uuid
import requests
import json
import ffmpeg
import pyttsx3
from datetime import timedelta

logger = logging.getLogger(__name__)

UNSPLASH_ACCESS_KEY = 'nmjW15652wGarnKPdSy0SQFWgQ7Y0Wu0UWOjluS9OSM'


@csrf_exempt
@api_view(['POST'])
def register_user(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response({'status': 'success', 'message': 'Signup successful'}, status=status.HTTP_201_CREATED)
    return Response({'status': 'failure', 'message': 'Signup failed', 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)


@csrf_exempt
@api_view(['POST'])
def login_user(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        return Response({
            'status': 'success',
            'message': 'Login successful',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'email': user.email,
                'full_name': getattr(user, 'full_name', '')
            }
        }, status=status.HTTP_200_OK)
    return Response({'status': 'failure', 'message': 'Invalid credentials', 'errors': serializer.errors}, status=status.HTTP_401_UNAUTHORIZED)


@csrf_exempt
def text_to_speech_view(request):
    if request.method != "POST":
        return HttpResponseBadRequest("Only POST requests allowed")

    try:
        data = json.loads(request.body)
        script = data.get("script")
        voice_gender = data.get("voice_gender", "female").lower()
        if not script:
            return JsonResponse({"error": "Missing 'script' parameter"}, status=400)

        media_dir = os.path.join(os.getcwd(), "media")
        os.makedirs(media_dir, exist_ok=True)
        output_path = os.path.join(media_dir, "output.mp3")

        engine = pyttsx3.init()
        voices = engine.getProperty('voices')

        # Function to find a voice by gender keyword in name or id
        def find_voice(gender_keyword):
            for v in voices:
                # Check 'male' or 'female' in voice name or id, case-insensitive
                if gender_keyword.lower() in v.name.lower() or gender_keyword.lower() in v.id.lower():
                    return v.id
            return None

        if voice_gender == "male":
            voice_id = find_voice("male")
            if voice_id is None:
                logger.warning("Male voice not found, defaulting to first voice")
                voice_id = voices[0].id
        else:
            voice_id = find_voice("female")
            if voice_id is None:
                logger.warning("Female voice not found, defaulting to first voice")
                voice_id = voices[0].id

        engine.setProperty('voice', voice_id)
        engine.save_to_file(script, output_path)
        engine.runAndWait()

        return JsonResponse({"message": "Audio generated successfully", "audio_file": output_path})

    except Exception as e:
        logger.exception("Text to speech generation failed")
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def fetch_unsplash_images(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            topic = data.get('topic')
            video_style = data.get('video_style')
            if not topic:
                return JsonResponse({'error': 'Topic is required'}, status=400)

            query = f"{video_style} {topic}" if video_style else topic
            url = f'https://api.unsplash.com/search/photos?query={query}&client_id={UNSPLASH_ACCESS_KEY}&per_page=10'
            response = requests.get(url)

            if response.status_code != 200:
                return JsonResponse({'error': 'Failed to fetch images from Unsplash'}, status=response.status_code)

            images = [img['urls']['regular'] for img in response.json().get('results', [])]
            if not images:
                return JsonResponse({'error': 'No images found'}, status=404)

            return JsonResponse({'image_urls': images}, status=200)
        except Exception as e:
            logger.exception("Fetching Unsplash images failed")
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'Only POST method allowed'}, status=405)


def generate_srt(script, duration, output_path):
    """
    Generates a simple SRT subtitle file splitting script into lines and
    distributing duration evenly.
    """
    lines = script.split(". ")
    time_per_line = duration / max(len(lines), 1)
    srt_lines = []

    def format_timedelta(td):
        total_seconds = int(td.total_seconds())
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60
        milliseconds = int((td.total_seconds() - total_seconds) * 1000)
        return f"{hours:02}:{minutes:02}:{seconds:02},{milliseconds:03}"

    for idx, line in enumerate(lines):
        start = timedelta(seconds=int(idx * time_per_line))
        end = timedelta(seconds=int((idx + 1) * time_per_line))
        srt_lines.append(
            f"{idx + 1}\n{format_timedelta(start)} --> {format_timedelta(end)}\n{line.strip()}\n"
        )

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(srt_lines))


@csrf_exempt
@api_view(['POST'])
def generate_video(request):
    try:
        script = request.data.get('script')
        image_urls = request.data.get('image_urls')
        video_style = request.data.get('video_style')

        if not all([script, image_urls, video_style]):
            return Response({'error': 'Missing fields'}, status=status.HTTP_400_BAD_REQUEST)

        media_dir = os.path.join(os.getcwd(), "media")
        os.makedirs(media_dir, exist_ok=True)

        audio_path = os.path.join(media_dir, "output.mp3")
        if not os.path.exists(audio_path):
            return Response({'error': 'Audio file not found. Generate it first via text-to-speech.'}, status=400)

        # Download images
        image_files = []
        topic = script.split()[0] if script else "topic"
        for i, url in enumerate(image_urls):
            img_path = os.path.join(media_dir, f"{topic}_{i}.jpg")
            with open(img_path, 'wb') as f:
                f.write(requests.get(url).content)
            image_files.append(img_path)

        # Create image input list for ffmpeg concat
        input_files_txt = os.path.join(media_dir, "input_images.txt")
        with open(input_files_txt, "w") as f:
            for img_file in image_files:
                f.write(f"file '{img_file}'\n")
                f.write("duration 3\n")
            f.write(f"file '{image_files[-1]}'\n")  # repeat last image for continuity

        # Create slideshow video from images
        raw_video_path = os.path.join(media_dir, "tmp_video.mp4")
        ffmpeg.input(input_files_txt, format='concat', safe=0).output(
            raw_video_path, vf='format=yuv420p', r=24
        ).run(overwrite_output=True)

        # Get video duration
        probe = ffmpeg.probe(raw_video_path)
        video_duration = float(next(stream for stream in probe['streams'] if stream['codec_type'] == 'video')['duration'])

        # Generate subtitle file (SRT)
        srt_path = os.path.join(media_dir, f"{topic}_subtitles.srt")
        generate_srt(script, video_duration, srt_path)

        # Merge video and audio into final video correctly
        final_video_filename = f"final_{topic}_{uuid.uuid4().hex[:6]}.mp4"
        final_video_path = os.path.join(media_dir, final_video_filename)

        video_input = ffmpeg.input(raw_video_path)
        audio_input = ffmpeg.input(audio_path)

        # Merge audio, video and embed subtitles as separate stream (soft subtitles)
        (
            ffmpeg
            .output(
                video_input.video,
                audio_input.audio,
                final_video_path,
                vcodec='libx264',
                acodec='aac',
                audio_bitrate='192k',
                shortest=None,
                **{'vf': 'format=yuv420p'}  # to ensure compatibility
            )
            .run(overwrite_output=True)
        )

        # You can optionally return the subtitle file URL separately for the frontend to load as soft subs
        video_url = request.build_absolute_uri(settings.MEDIA_URL + final_video_filename)
        subtitle_url = request.build_absolute_uri(settings.MEDIA_URL + os.path.basename(srt_path))

        return Response({
            'video_url': video_url,
            'subtitle_url': subtitle_url,
            'duration_seconds': round(video_duration, 2),
            'message': 'Video generated successfully',
            # The frontend can implement playback speed and share functionality using video_url
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.exception("Video generation failed")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
