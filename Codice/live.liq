# Questo file è un esempio di configurazione per Liquidsoap
# per creare uno stream HLS da una sorgente audio.

# Samuele Maria Orsini - 13/06/2025

settings.log.stdout.set(true)

# Definisco l'ingresso audio
radio = input.http("https://streaming.poliradio.it/test")

log.critical(label="Test", "Inizio dello script HLS")

# Definisco i parametri per l'encoding:
aac_lofi  = %ffmpeg(format="mpegts", 
                    %audio(codec="aac", 
                        channels=2, 
                        ar=48000))

aac_midfi = %ffmpeg(format="mpegts", 
                    %audio(codec="aac", 
                        channels=2, 
                        ar=48000, 
                        b="96k"))

aac_hifi = %ffmpeg(format="mpegts", 
                    %audio(codec="aac", 
                        channels=2, 
                        ar=48000, 
                        b="192k"))

# Definisco i vari stream che verranno emessi con i relativi parametri di encoding:
streams   = [("aac_lofi",  aac_lofi ),
             ("aac_midfi", aac_midfi),
             ("aac_hifi",  aac_hifi )]

# Definisco una funzione che crea i nomi dei segmenti
def segment_name(~position, ~extname, stream_name) =  timestamp = int_of_float(time())
  "#{stream_name}_#{timestamp}_#{position}.#{extname}"
end

# Definisco una funzione che reagisce alla creazione/eliminazione di segmenti (si può implementare altre cose)
#< def on_file_change(~state, fname)
    if state == "closed" then
      log.important(label="Test", "The file #{fname} was created.")
    elsif state == "removed" then
      log.important(label="Test", "The file #{fname} was removed.")
    end
end >#

def on_file_change(~state,fname) =
  if state == "closed" and file.extension(fname) != '.m3u8' then
      log.critical(label="test", "Test log on_file_change")
      log.critical(label="hls", "Segment #{fname} created")
  end
end

# Creo l'output HLS (vedere help/book per i parametri) #### errore linea 46 ####
output.file.hls(fallible=true,
                playlist          = "live.m3u8",
                segment_duration  = 5.,
                segments          = 60,
                segments_overhead = 12,
                on_file_change    = on_file_change,
                persist_at        = "state.config",
                "/tmp/hls", streams, radio) 

# Con questa funzione posso fare direttamente da Liquidsoap streaming HLS (senza nginx)
# ATTENZIONE: questa funzione è ancora in fase di sviluppo e potrebbe non funzionare correttamente, genera "glitch" sul cambio di segmento
# output.harbor.hls(port=8000, 
#                   fallible=true, 
#                   on_file_change=on_file_change, 
#                   segment_duration  = 2., 
#                   segments = 10, 
#                   segments_overhead = 5, 
#                   path="radio/", 
#                   [("mp3", %mp3)], radio)

#TEST 