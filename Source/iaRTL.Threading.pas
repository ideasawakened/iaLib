{
  Copyright 2023 Ideas Awakened Inc.
  Part of the "iaLib" shared code library for Delphi
  For more detail, see: https://github.com/ideasawakened/iaLib

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.


  Module History
  2.0 2023-04-29 Darian Miller: Migrated from old D5-compatible DXLib to iaLib for future work
}
unit iaRTL.Threading;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type

  TiaThread = class;
  TiaNotifyThreadEvent = procedure(const pThread:TiaThread) of object;
  TiaExceptionEvent = procedure(const pSender:TObject; const pException:Exception) of object;


  TiaThreadState = (tsActive, tsSuspended_NotYetStarted, tsSuspended_ManuallyStopped, tsSuspended_RunOnceCompleted, tsSuspendPending_StopRequestReceived, tsSuspendPending_RunOnceComplete, tsTerminated, tsAbortedDueToException);

  TiaThreadExecOption = (teRepeatRun, teRunThenSuspend, teRunThenFree);


  /// <summary>
  /// A TThread that can be managed (started/stopped) externally
  /// </summary>
  /// <remarks>
  /// Main differences from TThread:
  /// 1) Override the "Run" method instead of Execute.
  /// 2) Replace checking for "Terminated" with "ThreadIsActive"
  /// 3) Instead of using "Windows.Sleep", utilize this thread's "Sleep" method so it can be aborted when thread shutdown detected (for quicker thread termination)
  /// </remarks>
  TiaThread = class(TThread)
  private
    fThreadNameForDebugger:string;
    fLastThreadNameForDebugger:string;
    fThreadState:TiaThreadState;
    fStateChangeLock:TCriticalSection;

    fExecOptionInt:Integer;
    {$IFDEF MSWINDOWS}
    fRequireCoinitialize:Boolean;
    {$ENDIF}
    fTrappedException:Exception;
    fOnException:TiaExceptionEvent;
    fOnRunCompletion:TiaNotifyThreadEvent;
    fOnReportProgress:TGetStrProc;

    fAbortableSleepEvent:TEvent;
    fResumeSignal:TEvent;

    fOnProgressLock:TCriticalSection;
    fProgressReportsToSend:TArray<string>;


    /// <summary>
    /// The private getter method, GetThreadState, is used to safely access the
    /// current thread state field which could be set at any time by
    /// this/another thread while being continuously read by this/another thread.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    /// </remarks>
    function GetThreadState:TiaThreadState;

    /// <summary>
    /// The private getter method, GetExecOption, is used to read the current
    /// value of the ExecOption property
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    /// </remarks>
    function GetExecOption:TiaThreadExecOption;

    /// <summary>
    /// The private setter method, SetExecOption, is used to write the current
    /// value of the ExecOption property in an atomic transaction
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    /// </remarks>
    procedure SetExecOption(const NewValue:TiaThreadExecOption);

    /// <summary>
    /// The private method, SuspendThread, is use to deactivate an active
    /// thread.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    /// </remarks>
    procedure SuspendThread(const SuspendReason:TiaThreadState);

    /// <summary>
    /// The private method, Sync_CallOnReportProgress, is meant to be protected
    /// within a Synchronize call to safely execute the optional
    /// OnReportProgress event within the main thread's context
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    /// </remarks>
    procedure Sync_CallOnReportProgress;

    /// <summary>
    /// The private method, Sync_CallOnRunCompletion, is meant to be protected
    /// within a Synchronize call to safely execute the optional OnRunCompletion
    /// event within the main thread's context
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    /// </remarks>
    procedure Sync_CallOnRunCompletion;

    /// <summary>
    /// The private method, Sync_CallOnException, is meant to be protected
    /// within a Synchronize call to safely execute the optional OnException
    /// event within the main thread's context
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    /// </remarks>
    procedure Sync_CallOnException;

    /// <summary>
    /// The private method, DoOnRunCompletion, sets up the call to properly
    /// execute the OnRunCompletion event via Syncrhonize.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure DoOnRunCompletion;

    /// <summary>
    /// The private method, DoOnException, sets up the call to properly
    /// execute the OnException event via Syncrhonize.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure DoOnException;

    /// <summary>
    /// The private method, CallQueue, calls the TThread.Queue
    /// method using the passed in TThreadMethod parameter.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure CallQueue(const MethodToCall:TThreadMethod);


    /// <summary>
    /// The private read-only property, ThreadState, calls GetThreadState to
    /// determine the current fThreadState
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is referenced by outside threads OR by Self within its own context
    /// </remarks>
    property ThreadState:TiaThreadState read GetThreadState;
  protected

    /// <summary>
    /// The protected method, Execute, overrides TThread()'s abstract Execute
    /// method with common logic for handling thread descendants.  Instead of
    /// typical Delphi behavior of overriding Execute(), descendants should
    /// override the abstract Run method and also check for ThreadIsActive
    /// versus checking for Terminated.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed by Self within its own context.
    /// </remarks>
    procedure Execute; override;

    /// <summary>
    /// The Virtual protected method, BeforeRun, is an empty stub versus an
    /// abstract method to allow for optional use by descendants.
    /// Typically, common Scatter/Gather type operations happen in Before/AfterRun
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure BeforeRun; virtual; // Override as needed

    /// <summary>
    /// The Virtual protected method, BetweenRuns, is an empty stub versus an
    /// abstract method to allow for optional use by descendants.
    /// Typically, pause between executions occurs during this routine
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure BetweenRuns; virtual; // Override as needed


    /// <summary>
    /// The virtual Abstract protected method, Run, should be overriden by descendant
    /// classes to perform work. The option (TiaThreadExecOption) passed to
    /// Start controls how Run is executed.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure Run; virtual; abstract;


    /// <summary>
    /// The Virtual protected method, AfterRun, is an empty stub versus an
    /// abstract method to allow for optional use by descendants.
    /// Typically, common Scatter/Gather type operations happen in Before/AfterRun
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure AfterRun; virtual;

    /// <summary>
    /// The Virtual protected method, WaitForResume, is called when this thread
    /// is about to go inactive.  If overriding this method, descendants should
    /// peform desired work before the Inherited call.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure WaitForResume; virtual;

    /// <summary>
    /// The Virtual protected method, ThreadHasResumed, is called when this
    /// thread is returning to active state
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    /// </remarks>
    procedure ThreadHasResumed; virtual;

    /// <summary>
    /// The Virtual protected method, ExternalRequestToStop, is an empty stub
    /// versus an abstract method to allow for optional use by descendants.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is referenced within the thread-safe GetThreadState call by either
    /// outside threads OR by Self within its own context
    /// </remarks>
    function ExternalRequestToStop:Boolean; virtual;

    /// <summary>
    /// The protected method, ReportProgress, is meant to be reused by
    /// descendant classes to allow for a built in way to communicate back to
    /// the main thread via a synchronized OnReportProgress event.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// Optional. This is called by Self within its own context and only by
    /// descendants.
    /// </remarks>
    procedure ReportProgress(const AnyProgressText:string);

    /// <summary>
    /// The protected method, Sleep, is a replacement for windows.sleep
    /// intended to be use by descendant classes to allow for responding to
    /// thread suspension/termination if Sleep()ing.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// Optional. This is called by Self within its own context and only by
    /// descendants.
    /// </remarks>
    procedure Sleep(const SleepTimeMS:Integer);

    /// <summary>
    /// The protected property, ExecOption, is available for descendants to
    /// act in a hybrid manner (e.g. they can act as RepeatRun until a condition
    /// is hit and then set themselves to RunThenSuspend
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This property is referenced by outside threads OR by Self within its own
    /// context - which is the reason for InterlockedExchange in SetExecOption
    /// </remarks>
    property ExecOption:TiaThreadExecOption read GetExecOption write SetExecOption;

    {$IFDEF MSWINDOWS}
    /// <summary>
    /// The protected property, RequireCoinitialize, is available for
    /// descendants as a flag to execute CoInitialize before the thread Run
    /// loop and CoUnitialize after the thread Run loop.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This property is referenced by Self within its own context and should
    /// be set once during Creation (as it is referenced before the BeforeRun()
    /// event so the only time to properly set this is in the constructor)
    /// </remarks>
    property RequireCoinitialize:Boolean read fRequireCoinitialize write fRequireCoinitialize;
    {$ENDIF}
  public

    /// <summary>
    /// Public constructor for TiaThread, a descendant of TThread.
    /// Note: This constructor differs from TThread as all of these threads are
    /// started suspended by default.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    /// </remarks>
    constructor Create;

    /// <summary>
    /// Public destructor for TiaThread, a descendant of TThread.
    /// Note: This will automatically terminate/waitfor thread as needed
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed either within the calling thread's context
    /// OR within the threads context if auto-freeing itself
    /// </remarks>
    destructor Destroy; override;


    /// <summary>
    /// The public method, Start, is used to activate the thread to begin work.
    /// All TiaThreads are created in suspended mode and must be activated to do
    /// any work.
    ///
    /// Note: By default, the descendant's 'Run' method is continuously executed
    /// (BeforeRun, Run, AfterRun is performed in a loop) This can be overriden
    /// by overriding the ExecOption default parameter
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the calling thread's context either directly
    /// OR during a Destroy if the thread is released but never started (Which
    /// temporarily starts the thread in order to properly shut it down.)
    /// </remarks>
    function Start(const aExecOption:TiaThreadExecOption = teRepeatRun):Boolean;

    /// <summary>
    /// The public method, Stop, is a thread-safe way to deactivate a running
    /// thread.  The thread will continue operation until it has a chance to
    /// check the active status.
    /// Note:  Stop is not intended for use if ExecOption is teRunThenFree.
    ///
    /// This method will return without waiting for the thread to actually stop
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    /// </remarks>
    function Stop:Boolean;

    /// <summary>
    /// The public method, CanBeStarted is a thread-safe method to determine
    /// if the thread is able to be resumed at the moment.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    /// </remarks>
    function CanBeStarted:Boolean;

    /// <summary>
    /// The public method, ThreadIsActive is a thread-safe method to determine
    /// if the thread is actively running the assigned task.
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is referenced by outside threads OR by Self within its own context
    /// </remarks>
    function ThreadIsActive:Boolean;

    /// <remarks>
    ///  Note: use ASCII characters only until this bug is fixed (if ever) https://quality.embarcadero.com/browse/RSP-17452
    ///  iOS issues fixed in 11.1 https://quality.embarcadero.com/browse/RSP-29625
    ///  Linux issues fixed in 11.1 https://quality.embarcadero.com/browse/RSP-22083
    /// </remarks>
    property ThreadNameForDebugger:string read fThreadNameForDebugger write fThreadNameForDebugger;

    /// <summary>
    /// The protected method, WaitForHandle, is available for
    /// descendants as a way to Wait for a specific signal while respecting the
    /// Abortable Sleep signal on Stop requests, and also thread termination
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This method is referenced by Self within its own context and expected to
    /// be also be used by descendants
    /// event)
    /// </remarks>
    function WaitForHandle(const Handle:THandle):Boolean;

    /// <summary>
    /// The public event property, OnException, is executed when an error is
    /// trapped within the thread's Run loop
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    /// </remarks>
    property OnException:TiaExceptionEvent read fOnException write fOnException;

    /// <summary>
    /// The public event property, OnRunCompletion, is executed as soon as the
    /// Run method exits
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    /// </remarks>
    property OnRunCompletion:TiaNotifyThreadEvent read fOnRunCompletion write fOnRunCompletion;

    /// <summary>
    /// The public event property, OnReportProgress, is executed by descendant
    /// threads to report progress as needed back to the main thread
    /// </summary>
    /// <remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    /// </remarks>
    property OnReportProgress:TGetStrProc read fOnReportProgress write fOnReportProgress;

  end;


implementation

uses
  {$IFDEF MSWINDOWS}
  WinApi.ActiveX,
  WinApi.Windows,
  {$ENDIF}
  System.Types;


constructor TiaThread.Create;
begin
  inherited Create(True); // We always create suspended, user must always call Start()

  fThreadState := tsSuspended_NotYetStarted;
  fStateChangeLock := TCriticalSection.Create;
  fAbortableSleepEvent := TEvent.Create(nil, True, False, '');
  fResumeSignal := TEvent.Create(nil, True, False, '');
  fOnProgressLock := TCriticalSection.Create;
  fProgressReportsToSend := nil;
end;


destructor TiaThread.Destroy;
begin
  Terminate;
  if fThreadState <> tsSuspended_NotYetStarted then
  begin
    // if the thread is asleep...tell it to wake up so we can exit
    fAbortableSleepEvent.SetEvent;
    fResumeSignal.SetEvent;
  end;
  inherited;

  fStateChangeLock.Free;
  fResumeSignal.Free;
  fAbortableSleepEvent.Free;
  fOnProgressLock.Free;
end;


procedure TiaThread.Execute;
begin
  try // except

    if Length(fThreadNameForDebugger) > 0 then
    begin
      if fThreadNameForDebugger <> fLastThreadNameForDebugger then // NameThreadForDebugging only called as needed
      begin
        fLastThreadNameForDebugger := fThreadNameForDebugger;
        NameThreadForDebugging(fThreadNameForDebugger);
      end;
    end;

    while not Terminated do
    begin
      {$IFDEF MSWINDOWS}
      if fRequireCoinitialize then
      begin
        CoInitialize(nil);
      end;
      try
        {$ENDIF}
        ThreadHasResumed;
        BeforeRun;
        try
          while ThreadIsActive do // check for stop, externalstop, terminate
          begin
            Run; // descendant's code
            DoOnRunCompletion;

            case ExecOption of
              teRepeatRun:
                begin
                  BetweenRuns;
                  // then loop
                end;
              teRunThenSuspend:
                begin
                  SuspendThread(tsSuspendPending_RunOnceComplete);
                  Break;
                end;
              teRunThenFree:
                begin
                  FreeOnTerminate := True;
                  Terminate;
                  Break;
                end;
            end;
          end; // while ThreadIsActive()
        finally
          AfterRun;
        end;
        {$IFDEF MSWINDOWS}
      finally
        if fRequireCoinitialize then
        begin
          // ensure this is called if thread is to be suspended
          CoUnInitialize;
        end;
      end;
      {$ENDIF}
      // Thread entering wait state
      WaitForResume;
      // Note: Only two reasons to wake up a suspended thread:
      // 1: We are going to terminate it
      // 2: we want it to restart doing work
    end; // while not Terminated

  except
    on E:Exception do
    begin
      fTrappedException := E;
      DoOnException;
    end;
  end;
end;


procedure TiaThread.WaitForResume;
begin
  fStateChangeLock.Enter;
  try
    if fThreadState = tsSuspendPending_StopRequestReceived then
    begin
      fThreadState := tsSuspended_ManuallyStopped;
    end
    else if fThreadState = tsSuspendPending_RunOnceComplete then
    begin
      fThreadState := tsSuspended_RunOnceCompleted;
    end;

    fResumeSignal.ResetEvent;
    fAbortableSleepEvent.ResetEvent;
  finally
    fStateChangeLock.Leave;
  end;

  WaitForHandle(fResumeSignal.Handle);
end;


procedure TiaThread.ThreadHasResumed;
begin
  // If we resumed a stopped thread, then a reset event is needed as it
  // was set to trigger out of any pending sleeps to pause the thread
  fAbortableSleepEvent.ResetEvent;
  fResumeSignal.ResetEvent;
end;


function TiaThread.ExternalRequestToStop:Boolean;
begin
  // Intended to be overriden - for descendant's use as needed
  Result := False;
end;


procedure TiaThread.BeforeRun;
begin
  // Intended to be overriden - for descendant's use as needed
end;


procedure TiaThread.BetweenRuns;
begin
  // Intended to be overriden - for descendant's use as needed
end;


procedure TiaThread.AfterRun;
begin
  // Intended to be overriden - for descendant's use as needed
end;


function TiaThread.Start(const aExecOption:TiaThreadExecOption = teRepeatRun):Boolean;
begin
  if fStateChangeLock.TryEnter then
  begin
    try
      ExecOption := aExecOption;

      Result := CanBeStarted;
      if Result then
      begin
        if fThreadState = tsSuspended_NotYetStarted then
        begin
          fThreadState := tsActive;
          // We haven't started Exec loop at all yet
          // Since we start all threads in suspended state, we need one initial Resume()
          inherited Start;
        end
        else
        begin
          fThreadState := tsActive;
          // we're waiting on Exec, wake up and continue processing
          fResumeSignal.SetEvent;
        end;
      end;
    finally
      fStateChangeLock.Leave;
    end;
  end
  else // thread is not asleep
  begin
    Result := False;
  end;
end;


function TiaThread.Stop:Boolean;
begin
  if ExecOption <> teRunThenFree then
  begin
    fStateChangeLock.Enter;
    try
      if ThreadIsActive then
      begin
        Result := True;
        SuspendThread(tsSuspendPending_StopRequestReceived);
      end
      else
      begin
        Result := False;
      end;
    finally
      fStateChangeLock.Leave;
    end;
  end
  else
  begin
    // Never allowed to stop a FreeOnTerminate thread as we cannot properly
    // control thread termination from the outside in that scenario.
    Result := False;
  end;
end;


procedure TiaThread.SuspendThread(const SuspendReason:TiaThreadState);
begin
  fStateChangeLock.Enter;
  try
    fThreadState := SuspendReason; // will auto-suspend thread in Exec

    // If we are sleeping in the RUN loop, wake up and check stopped
    // which is why you should use self.Sleep(x) instead of windows.sleep(x)
    // AND why the sleep between iterations (if any) in the RUN should be the
    // last line, and not the first line.
    fAbortableSleepEvent.SetEvent;
  finally
    fStateChangeLock.Leave;
  end;
end;


procedure TiaThread.Sync_CallOnRunCompletion;
begin
  if not Terminated then
  begin
    fOnRunCompletion(Self);
  end;
end;


procedure TiaThread.DoOnRunCompletion;
begin
  if Assigned(fOnRunCompletion) then
  begin
    CallQueue(Sync_CallOnRunCompletion);
  end;
end;


procedure TiaThread.Sync_CallOnException;
begin
  if not Terminated then
  begin
    fOnException(Self, fTrappedException);
  end;
end;


procedure TiaThread.DoOnException;
begin
  if Assigned(fOnException) then
  begin
    CallQueue(Sync_CallOnException);
  end;
  fStateChangeLock.Enter;
  try
    fThreadState := tsAbortedDueToException;
  finally
    fStateChangeLock.Leave;
  end;
  fTrappedException := nil;
end;


function TiaThread.GetThreadState:TiaThreadState;
begin
  fStateChangeLock.Enter;
  try
    if Terminated then
    begin
      fThreadState := tsTerminated;
    end
    else if ExternalRequestToStop then // used by central Thread Manager
    begin
      fThreadState := tsSuspendPending_StopRequestReceived;
    end;
    Result := fThreadState;
  finally
    fStateChangeLock.Leave;
  end;
end;


function TiaThread.GetExecOption:TiaThreadExecOption;
begin
  Result := TiaThreadExecOption(System.AtomicCmpExchange(fExecOptionInt, 0, 0));
end;


procedure TiaThread.SetExecOption(const NewValue:TiaThreadExecOption);
begin
  System.AtomicExchange(fExecOptionInt, Ord(NewValue));
end;


function TiaThread.CanBeStarted:Boolean;
begin
  if fStateChangeLock.TryEnter then
  begin
    try
      Result := (not Terminated) and (fThreadState in [tsSuspended_NotYetStarted, tsSuspended_ManuallyStopped, tsSuspended_RunOnceCompleted]);

    finally
      fStateChangeLock.Leave;
    end;
  end
  else // thread isn't asleep
  begin
    Result := False;
  end;
end;


function TiaThread.ThreadIsActive:Boolean;
begin
  Result := (not Terminated) and (ThreadState = tsActive);
end;


procedure TiaThread.Sleep(const SleepTimeMS:Integer);
begin
  if not Terminated then
  begin
    fAbortableSleepEvent.WaitFor(SleepTimeMS);
  end;
end;


procedure TiaThread.CallQueue(const MethodToCall:TThreadMethod);
begin
  Queue(MethodToCall); // Unlike Synchronize, execution of the current thread is allowed to continue. The main thread will eventually process all queued methods.
end;


procedure TiaThread.Sync_CallOnReportProgress;
var
  ProgressText:string;
begin
  if not Terminated then
  begin
    fOnProgressLock.Enter; // we are currently in the main thread - manage access to fProgressReportsToSend with worker thread that may want to add another progress report
    try
      if Length(fProgressReportsToSend) > 0 then
      begin
        ProgressText := fProgressReportsToSend[0]; // FIFO
        Delete(fProgressReportsToSend, 0, 1);
      end;
    finally
      fOnProgressLock.Leave;
    end;
    fOnReportProgress(ProgressText);
  end;
end;


procedure TiaThread.ReportProgress(const AnyProgressText:string);
begin
  if Assigned(fOnReportProgress) then
  begin
    fOnProgressLock.Enter; // we are currently in the worker thread - manage access to fProgressReportsToSend with main thread that may be dequeing a previous progress report right now
    try
      fProgressReportsToSend := fProgressReportsToSend + [AnyProgressText];
      CallQueue(Sync_CallOnReportProgress);
    finally
      fOnProgressLock.Leave;
    end;
  end;
end;


function TiaThread.WaitForHandle(const Handle:THandle):Boolean;
const
  WaitAllOption = False;
  IterateTimeOutMilliseconds = 200;
var
  vWaitForEventHandles: array [0 .. 1] of THandle;
  vWaitForResponse:DWord;
begin
  Result := False;
  vWaitForEventHandles[0] := Handle; // initially for: fResumeSignal.Handle;
  vWaitForEventHandles[1] := fAbortableSleepEvent.Handle;

  while not Terminated do
  begin
    {$IFDEF MSWINDOWS}
    vWaitForResponse := WaitForMultipleObjects(2, @vWaitForEventHandles[0], WaitAllOption, IterateTimeOutMilliseconds);
    {$ELSE}
    {$MESSAGE TiaThread not yet cross-platform...}
    {$ENDIF}
    case vWaitForResponse of
      WAIT_TIMEOUT:
        begin
          Continue;
        end;
      WAIT_OBJECT_0:
        begin
          Result := True; // initially for Resume, but also for descendants to use
          Break;
        end;
      WAIT_OBJECT_0 + 1:
        begin
          fAbortableSleepEvent.ResetEvent; // likely a stop received while we are waiting for an external handle
          Break;
        end;
      WAIT_FAILED:
        begin
          RaiseLastOSError;
        end;
    end;
  end; // while not Terminated
end;


end.
