// Original ALSAbeep() from beeper.inc by
// Robert Rozee, 30-April-2020
// <rozee@mail.com>
 
// The ALSA types, constants and functions
// are copied from pwm.inc of fpAlsa by
// Nikolay Nikolov <nickysn@users.sourceforge.net>

// Turned into unit and dynamic loading by
// Fred vS <fiens@hotmail.com>
 
// ALSAbeep by Robert Rozee.
// ALSAglide by Winni.
// ALSApolice by Winni.
// ALSAbeepstereo by Fred vS.
 
unit alsa_sound;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  dynlibs,
  CTypes;
 
type
  // Signed frames quantity
  snd_pcm_sframes_t = cint;

  // PCM handle
  PPsnd_pcm_t = ^Psnd_pcm_t;
  Psnd_pcm_t  = Pointer;

  // PCM stream (direction) 
  snd_pcm_stream_t = cint;

  // PCM sample format
  snd_pcm_format_t = cint;

  // PCM access type
  snd_pcm_access_t = cint;

  // Unsigned frames quantity
  snd_pcm_uframes_t = cuint;

const
  // Playback stream
  SND_PCM_STREAM_PLAYBACK: snd_pcm_stream_t = 0;

  // Unsigned 8 bit
  SND_PCM_FORMAT_U8: snd_pcm_format_t       = 1;

  // snd_pcm_readi/snd_pcm_writei access
  SND_PCM_ACCESS_RW_INTERLEAVED: snd_pcm_access_t = 3;
  
// Dynamic load : Vars that will hold our dynamically loaded ALSA methods...
var
  snd_pcm_open: function(pcm: PPsnd_pcm_t; Name: PChar; stream: snd_pcm_stream_t; mode: cint): cint; cdecl;

  snd_pcm_set_params: function(pcm: Psnd_pcm_t; format: snd_pcm_format_t; access: snd_pcm_access_t; channels, rate: cuint; soft_resample: cint; latency: cuint): cint; cdecl;

  snd_pcm_writei: function(pcm: Psnd_pcm_t; buffer: Pointer; size: snd_pcm_uframes_t): snd_pcm_sframes_t; cdecl;

  snd_pcm_recover: function(pcm: Psnd_pcm_t; err, silent: cint): cint; cdecl;

  snd_pcm_drain: function(pcm: Psnd_pcm_t): cint; cdecl;

  snd_pcm_close: function(pcm: Psnd_pcm_t): cint; cdecl;

// Special function for dynamic loading of lib ...
  as_Handle: TLibHandle = dynlibs.NilHandle; // this will hold our handle for the lib

  ReferenceCounter: cardinal = 0;  // Reference counter

function as_IsLoaded: Boolean; inline;

function as_Load: Boolean; // load the lib

procedure as_Unload();     // unload and frees the lib from memory : do not forget to call it before close application.

function ALSAbeep(frequency, duration, volume: integer; warble: Boolean; CloseLib: boolean): Boolean;

function ALSAbeep1: Boolean; // fixed beep at 660 HZ, mono, 100 ms, 75 % volume
function ALSAbeep2: Boolean; // fixed beep at 440 HZ, mono, 100 ms, 75 % volume
function ALSAbeep3: Boolean; // fixed beep at 220 HZ, mono, 100 ms, 75 % volume

function ALSAbeepStereo(Frequency1, Frequency2, Duration, Volume1, Volume2: integer; warble: Boolean; CloseLib: boolean): Boolean;

function ALSAglide(StartFreq,EndFreq, duration, volume: integer; CloseLib: boolean): Boolean;

implementation

function Max(a, b: Integer): Integer; inline;
begin
if a > b then
    Result := a
  else
    Result := b;
end;

function EnsureFreq(const AValue, AMin, AMax: Integer): Integer; inline;
begin
  Result:=AValue;
  If Result<AMin then
    Result:=AMin;
  if Result>AMax then
    Result:=AMax;
end;

function EnsureSpeed(const AValue: single): single; inline;
begin
 result := abs(AValue);
 if result < 0.1 then result := 0.1
end;

function EnsureDuration(const AValue: integer): integer; inline;
begin
 result := abs(AValue);
 if result < 50 then result := 50;
end;

function EnsureVolume(const AValue: integer): integer; inline;
begin
 result := abs(AValue);
 if result < 0 then result := 0
 else if result > 100 then result := 100;
end;

function as_IsLoaded: Boolean;
begin
  Result := (as_Handle <> dynlibs.NilHandle);
end;

function as_Load: Boolean; // load the lib
var
  thelib: string = 'libasound.so.2';
begin
  Result := False;
  if as_Handle <> dynlibs.NilHandle then
  begin
    Inc(ReferenceCounter);
    Result := True; // is it already there ?
  end
  else
  begin // go & load the library
    as_Handle := DynLibs.SafeLoadLibrary(thelib); // obtain the handle we want
    if as_Handle <> DynLibs.NilHandle then
    begin // now we tie the functions to the VARs from above

      Pointer(snd_pcm_open)       := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_open'));
      Pointer(snd_pcm_set_params) := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_set_params'));
      Pointer(snd_pcm_writei)     := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_writei'));
      Pointer(snd_pcm_recover)    := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_recover'));
      Pointer(snd_pcm_recover)    := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_recover'));
      Pointer(snd_pcm_drain)      := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_drain'));
      Pointer(snd_pcm_close)      := DynLibs.GetProcedureAddress(as_Handle, PChar('snd_pcm_close'));

      Result           := as_IsLoaded;
      ReferenceCounter := 1;
    end;
  end;
end;

procedure as_Unload();
begin
  // < Reference counting
  if ReferenceCounter > 0 then
    Dec(ReferenceCounter);
  if as_IsLoaded then
  begin
    DynLibs.UnloadLibrary(as_Handle);
    as_Handle := DynLibs.NilHandle;
  end;
end;

function ALSAglide(StartFreq,EndFreq, duration, volume: integer; CloseLib: boolean): Boolean;
    var
      buffer: array[0..9600 - 1] of byte; // 1/5th second worth of samples @48000Hz
      frames: snd_pcm_sframes_t;   // number of frames written (negative if an error occurred)
      pcm: PPsnd_pcm_t;            // sound device handle
      I, FC: integer;
      SA: array[0..359] of shortint;  // array of sine wave values for a single cycle
    const
      device = 'default' + #0;        // name of sound device
    var
      count1, count2, N, X: integer;
      DeltaStep: single;   //winni
      delta : Integer;     //  "
    begin
      Result := False;
     
      as_Load;     // load the library
     
      if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
        if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
          SND_PCM_ACCESS_RW_INTERLEAVED,
          1,                  // number of channels
          48000,              // sample rate (Hz)
          1,                  // resampling on/off
          500000) = 0 then    // latency (us)
        begin
          Result := True;
         
          StartFreq:= EnsureFreq(abs(StartFreq),20,20000);
          EndFreq  := EnsureFreq(abs(EndFreq),20,20000);
          duration := EnsureDuration(duration);
          volume   := EnsureVolume(Volume);
                       
          // 48 samples per ms -->
          // 360 / 48 = 7.5
       
          DeltaStep := 7.5*(EndFreq - startFreq) /(duration);   // winni
     
          for I := 0 to 359 do
            SA[I] := round(sin(pi * I / 180.0) * volume); // create sine wave pattern
          X       := 0;
          N       := 0;   // up/down counter used by unequal interval division
     
          count1 := 0;              // count1 counts up, count2 counts down
          count2 := duration * 48;  // (at 48000Hz there are 48 samples per ms)
     
          while count2 > 0 do              // start making sound!
          begin
            FC    := 0;
            for I := 0 to sizeof(buffer) - 1 do   // fill buffer with samples
            begin
              if count2 > 0 then
              begin
                if count1 < 480 then
                  buffer[I] := 128 + ((count1 * SA[X]) div 480)
                else   // 10ms feather in
                if count2 < 480 then
                  buffer[I] := 128 + ((count2 * SA[X]) div 480)
                else   // 10ms feather out
                  buffer[I] := 128 + SA[X];
                Inc(FC);
              end
              else
              begin
                buffer[I] := 128;  // no signal on trailing end of buffer, just in case
                if (FC mod 2400) <> 0 then
                  Inc(FC);   // keep increasing FC until is a multiple of 2400
              end;
     
             delta := round (Count1*DeltaStep);   // winni
             Inc(N,StartFreq*360+Delta);          // winni
              while (N > 0) do
              begin                  // (a variation on Bresenham's Algorithm)
                Dec(N, 48000);
                Inc(X);
              end;
              X := X mod 360;
     
              Inc(count1);
              Dec(count2);
            end;
            
          frames   := snd_pcm_writei(pcm, @buffer, max(2400,FC)); // write AT LEAST one full period
      
            if frames < 0 then
              frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
            if frames < 0 then
              break;                            // give up if failed to recover
          end;
          snd_pcm_drain(pcm);                   // drain any remaining samples
          snd_pcm_close(pcm);
        end;
        if CloseLib then as_unload;  // Unload library if param CloseLib is true
    end; //AlsaGlide
  
function ALSAbeep(frequency, duration, volume: integer; warble: Boolean; CloseLib : boolean): Boolean;
var
  buffer: array[0..(9600) - 1] of byte;  // 1/5th second worth of samples @48000Hz
 frames: snd_pcm_sframes_t;           // number of frames written (negative if an error occurred)
  pcm: PPsnd_pcm_t;                    // sound device handle
  I, FC: integer;
  SA: array[0..359] of shortint;       // array of sine wave values for a single cycle

 const
  device = 'default' + #0;             // name of sound device
var
  count1, count2, N, X: integer;
begin
  Result := False;

  as_Load;       // load the library

  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      1,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then            // latency (us)
    begin
      Result := True;
    
      frequency:= EnsureFreq(abs(frequency),20,20000);
      duration := EnsureDuration(duration);
      volume   := EnsureVolume(Volume);
             
      for I := 0 to 359 do
        SA[I] := round(sin(pi * I / 180.0) * volume);  // create sine wave pattern
    
      X       := 0;
      N       := 0;       // up/down counter used by unequal interval division

      count1 := 0;        // count1 counts up, count2 counts down
      count2 := duration * 48;     // (at 48000Hz there are 48 samples per ms)

      while count2 > 0 do       // start making sound!
      begin
        FC    := 0;
        for I := 0 to sizeof(buffer) - 1 do   // fill buffer with samples
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
              buffer[I] := 128 + ((count1 * SA[X]) div 480)
            else   // 10ms feather in
            if count2 < 480 then
              buffer[I] := 128 + ((count2 * SA[X]) div 480)
            else   // 10ms feather out
              buffer[I] := 128 + SA[X];
            if warble and odd(count1 div 120) then
              buffer[I] := 128;              // 200Hz warble
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;  // no signal on trailing end of buffer, just in case
            if (FC mod 2400) <> 0 then
              Inc(FC);        // keep increasing FC until is a multiple of 2400
          end;

          Inc(N, frequency * 360); // unequal interval division routine
          while (N > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;

          Inc(count1);
          Dec(count2);
        end; 
        
        frames   := snd_pcm_writei(pcm, @buffer, max(2400,FC)); // write AT LEAST one full period
    
        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                        // give up if failed to recover
      end;
      snd_pcm_drain(pcm);              // drain any remaining samples
      snd_pcm_close(pcm);
    end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end; // ALSAbeep

function ALSAbeep1: Boolean; // beep at 660 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(660, 100, 75, false, true);
end;

function ALSAbeep2: Boolean; // beep at 440 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(440, 100, 75, false, true);
end;

function ALSAbeep3: Boolean; // beep at 220 HZ, mono, 100 ms, 75 % volume
begin
result := ALSAbeep(220, 100, 75, false, true);
end;

function ALSAbeepStereo(Frequency1, Frequency2, Duration, Volume1, Volume2: integer; warble: Boolean; CloseLib : boolean): Boolean;
var
  buffer: array[0..(9600*2) - 1] of byte;  // 1/5th second worth of samples @48000Hz
  frames: snd_pcm_sframes_t;           // number of frames written (negative if an error occurred)
  pcm: PPsnd_pcm_t;                    // sound device handle
  I, FC: integer;
  SA, SA2: array[0..359] of shortint;       // array of sine wave values for a single cycle
const
  device = 'default' + #0;             // name of sound device
var
  count1, count2, N, N2, X, X2: integer;
begin
  Result := False;

  as_Load;       // load the library

  if snd_pcm_open(@pcm, @device[1], SND_PCM_STREAM_PLAYBACK, 0) = 0 then
    if snd_pcm_set_params(pcm, SND_PCM_FORMAT_U8,
      SND_PCM_ACCESS_RW_INTERLEAVED,
      2,                        // number of channels
      48000,                    // sample rate (Hz)
      1,                        // resampling on/off
      500000) = 0 then            // latency (us)
    begin
      Result := True;
  
       frequency1:= EnsureFreq(abs(frequency1),20,20000); 
      volume1   := EnsureVolume(Volume1);
        frequency2:= EnsureFreq(abs(frequency2),20,20000); 
        volume2   := EnsureVolume(Volume2);
        duration := EnsureDuration(duration);
      
      for I := 0 to 359 do
        SA[I] := round(sin(pi * I / 180.0) * volume1);  // create sine wave pattern
        
      for I := 0 to 359 do
        SA2[I] := round(sin(pi * I / 180.0) * volume2);  // create sine wave pattern
                          
      X       := 0;
      N       := 0;       // up/down counter used by unequal interval division
                             
      X2       := 0;   // stereo
      N2       := 0; 

      count1 := 0;        // count1 counts up, count2 counts down
      count2 := duration * 48;     // (at 48000Hz there are 48 samples per ms)

      while count2 > 0 do       // start making sound!
      begin
        FC    := 0;
        I    := 0;
        while I < sizeof(buffer) do
        begin
          if count2 > 0 then
          begin
            if count1 < 480 then
            begin
           buffer[I] := 128 + ((count1 * SA[X]) div 480);
           buffer[I+1] := 128 + ((count1 * SA2[X2]) div 480);
            end  
            else   // 10ms feather in
            if count2 < 480 then
            begin
            buffer[I] := 128 + ((count2 * SA[X]) div 480);
            buffer[I+1] := 128 + ((count2 * SA2[X2]) div 480);
            end  
            else   // 10ms feather out
            begin
              buffer[I] := 128 + (SA[X]);
              buffer[I+1] := 128 + (SA2[X2]);
            end;  
            if warble and odd(count1 div 120) then
            begin
            buffer[I] := 128;              // 200Hz warble
            buffer[I+1] := 128;
            end;
            Inc(FC);
          end
          else
          begin
            buffer[I] := 128;  // no signal on trailing end of buffer, just in case
            buffer[I+1] := 128;
            if (FC mod 2400) <> 0 then
              Inc(FC);        // keep increasing FC until is a multiple of 2400
          end;

          Inc(N, frequency1 * 360); // unequal interval division routine
          while (N > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N, 48000);
            Inc(X);
          end;
          X := X mod 360;
          
           Inc(N2, (frequency2 div 2) * 360); // unequal interval division routine
          while (N2 > 0) do
          begin                    // (a variation on Bresenham's Algorithm)
            Dec(N2, 48000);
            Inc(X2);
          end;
          X2 := X2 mod 360;

          Inc(count1);
          Dec(count2);
          
          inc(I,2);
        end; 
        
       frames   := snd_pcm_writei(pcm, @buffer,max(2400,FC)); // write AT LEAST one full period
    
        if frames < 0 then
          frames := snd_pcm_recover(pcm, frames, 0); // try to recover from any error
        if frames < 0 then
          break;                        // give up if failed to recover
      end;
      snd_pcm_drain(pcm);              // drain any remaining samples
      snd_pcm_close(pcm);
    end;
   if CloseLib then as_unload;  // Unload library if param CloseLib is true
end; // ALSAbeepstereo

finalization  // in case if library was not unloaded.
as_unload;

end.
