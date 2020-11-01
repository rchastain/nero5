
const
  CDate = {$I %DATE%};
  CTime = {$I %TIME%};
  CFPCV = {$I %FPCVERSION%};
  CTRGC = {$I %FPCTARGETCPU%};
  CTRGO = {$I %FPCTARGETOS%};
  CAppName  = 'Nero';
  CMajorVer = '5';
  CMinorVer = '0.1';
  CBuild    = 'build ' + CDate + ' ' + CTime + ' FPC ' + CFPCV + ' ' + CTRGC + ' ' + CTRGO;
  CAppInfo  = CAppName + ' ' + CMajorVer + '.' + CMinorVer + ' ' + CBuild ;
