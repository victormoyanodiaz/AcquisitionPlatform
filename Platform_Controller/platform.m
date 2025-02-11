%%VICTOR MOYANO
%%Class to control the rotation platform.
%%20/06/2016


classdef platform < handle
    %PLATFORM This class is provided to control the rotating platform.
    
    properties(SetAccess = private, Hidden = true)
        connection= 'NULL';
        changeDirectionCorrection= 122; %122 adittional steps are needed each time the direction changes.
        smallStepsAcelerationRatio= 0.4;
        smallStepsDecelerationRatio= 0.6;
        
    end
    
    properties(Constant, Hidden = true)
        propertiesNames= {'maximumCurrent','deviceMode','positiveDirectionOfRotation', ...
        'decelerationSteps','acelerationSteps','rotationSpeed', ...
        'stepsForCompleteRotation','stepType','stopCurrent','searchForLimit', ...
        'continousMovement','waitForMoveToFinish','originPosition'};
        maximumCurrentValues= {'minimum Value: 1', 'maximum Value: 200'};
        deviceModeValues= {'Serie','Enable','Track','Special'};
        positiveDirectionOfRotationValues= {'Clockwise','AntiClockwise'};
        decelerationStepsValues= {'minimum  Value: 0', 'maximum Value: 999'};
        acelerationStepsValues= {'minimum  Value: 0', 'maximum Value: 999'};
        rotationSpeedValues= {'minimum Value: 1', 'maximum Value: 200'};
        stepsForCompleteRotationValues = {200, 300};
        stepTypeValues= {'Full Steps','Half Steps','16 microSteps','32 microSteps', ...
            '64 microSteps'};
        stopCurrentValues= {'15%','40%','55%','75%'};
        searchForLimitValues= {'False','True'};
        continousMovementValues= {'False','True'};
        waitForMoveToFinishValues= {'False', 'True'};
        nParameters= 13;
        reductoraEngine1= 1/40;
        reductoraEngine2= 1/40;
        degreesPerStep= 360/(200*40);
        %this is susceptible to be changed. In this case, both engines have the same reduction applied, but could be different.
    end
    
    properties(SetAccess = public)
        maximumCurrent = 105; %%user Units (not mA )
        deviceMode= 'Serie';
        positiveDirectionOfRotation = 'Clockwise'; %rotation direction
        decelerationSteps = 999;
        acelerationSteps= 500;
        rotationSpeed = 20; %rpm
        stepsForCompleteRotation = 200; %steps for 360 rotation
        stepType= '16 microSteps';
        stopCurrent='15%';
        searchForLimit= 'False';
        continousMovement= 'False';
        waitForMoveToFinish = 'True';
        lastMove= 'Clockwise';
        originPosition= [0 0];
    end 
    
    methods
        
        function this = platform(varargin)
            %%New platform object. Connect to the platform.
             this.connection= serial('COM3','BaudRate',19200,'Terminator',13);
             fopen(this.connection);
             this.refreshParameters();
            
        end
        
        function delete(this,varargin)
            %%DELETE - Destroys the nikon handle and closes the camera connection.
            %
            %PARAMETERS:
            %   1 inputs --> input any string, to not return to origin
            %OUTPUT: 
            %   O output
            
             if((this.originPosition(1)~= 0 || this.originPosition(2)~= 0) && isempty(varargin))
                 
                 

                 this.move(this.originPosition);
             end
             fclose(this.connection);
%             
            %disp('Serial port closed');
        end
        
        %------------------------SET FUNCTIONS-----------------------------
        function set(this,varargin)
            %%set - this function sets the value of a given parameters
            %---PARAMETERS:
            %------1 INPUT: Struct containing the parameters and the values
            %to be set.
            %------2N INPUTS: N is the number of parameters to set. The position N
            % should contain the name of the parameter, and the position N+1 contains
            % the value to be set. 
            %parameters.
            %---OUTPUT:
            %------0 OUTPUT.
            if(length(varargin) == 1)%%The user is hopefully passing a struct
                if(isstruct(varargin{1}))
                    parameters= varargin{1};
                    varargin= {};
                    fieldNames= fieldnames(parameters);
                    for i=1:length(fieldNames)
                        varargin= [varargin fieldNames(i) parameters.(char(fieldNames(i)))];
                    end
                else
                    error('An struct should be passed as parameters, if you plan to set values with one input');
                end
            end
            if(length(varargin)>=2 && mod(length(varargin),2)==0)
                for i=1:2:length(varargin)
                    parameterName= validatestring(varargin{i},this.propertiesNames); %autocomplete function
                    if(strcmp('maximumCurrent',parameterName))
                        if(varargin{i+1}>1 && varargin{i+1} <200)
                            this.maximumCurrent= varargin{i+1};
                        else
                            error('Value entered for maximumCurrent is not valid. Enter a value between 1 and 200');
                        end  
                        
                    elseif(strcmp('deviceMode',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.deviceModeValues);
                        catch
                            error('Value entered in the parameter deviceMode should be either Serie, Enable, Track or Special. Please check it');
                        end
                        this.deviceMode= paramValue; 
                        
                    elseif(strcmp('positiveDirectionOfRotation',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.positiveDirectionOfRotationValues);
                        catch
                            error('Value entered in the parameter directionOfRotation should be either Clockwise or AntiClockwise. Please check it.');
                        end
                        this.positiveDirectionOfRotation= paramValue;  
                        
                    elseif(strcmp('decelerationSteps',parameterName))
                        if(varargin{i+1}>=0 && varargin{i+1} <1000)
                            this.decelerationSteps= varargin{i+1};
                        else
                            error('Value entered for decelerationSteps is not valid. Enter a value between 1 and 1000');
                        end  
                        
                    elseif(strcmp('acelerationSteps',parameterName))
                        if(varargin{i+1}>=9 && varargin{i+1} <1000)
                            this.acelerationSteps= varargin{i+1};
                        else
                            error('Value entered for acelerationSteps is not valid. Enter a value between 1 and 1000');
                        end  
                        
                    elseif(strcmp('rotationSpeed',parameterName))
                        if(varargin{i+1}>=1 && varargin{i+1} <200)
                            this.rotationSpeed = varargin{i+1};
                        else
                            error('Value entered for rotationSpeed is not valid. Enter a value between 1 and 200');
                        end  
                        
                    elseif(strcmp('stepsForCompleteRotation',parameterName))
                        if(varargin{i+1}==400 || varargin{i+1} ==200)
                            this.stepsForCompleteRotation = varargin{i+1};
                        else
                            error('Value entered for stepsForCompleteRotation is not valid. Enter 400 or 200');
                        end  
                        
                    elseif(strcmp('stepType',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.stepTypeValues);
                        catch
                            error(['The value entered in the parameter stepType should be either Full Steps, Half Steps,' ...
                    '16 microSteps, 32 microSteps or 64 microSteps. Please check it.']);
                        end
                        this.stepType= paramValue; 
                        
                    elseif(strcmp('stopCurrent',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.stopCurrentValues);
                        catch
                            error(['The value entered in the parameter stopCurrent should be either 15%, 40%,' ...
                    '55%, 75%. Please check it.']);
                        end
                        this.stopCurrent= paramValue; 
                        
                    elseif(strcmp('searchForLimit',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.searchForLimitValues);
                        catch
                            error('The value entered in the parameter stopCurrent should be either True or False.');
                        end
                        this.searchForLimit= paramValue; 
                        
                    elseif(strcmp('continousMovement',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.continousMovementValues);
                        catch
                            error('The value entered in the parameter continousMovement should be either True or False.');
                        end
                        this.continousMovement= paramValue; 
                        
                    elseif(strcmp('waitForMoveToFinish',parameterName))
                        try
                            paramValue= validatestring(varargin{i+1},this.waitForMoveToFinishValues);
                        catch
                            error('The value entered in the parameter waitForMoveToFinish should be either True or False.');
                        end
                        this.waitForMoveToFinish= paramValue; 
                        
                    elseif(strcmp('originPosition',parameterName))
                        %Warning('The propierty goToOrigin cant be set manually. It is managed by this software.');
                    else
                        error('Parameter not recognized.');
                    end
                end
            else
                error('You must enter a parameter name, and its value.');
            end
        end
        
        %------------------------GET FUNCTION------------------------------
        function parameters= get(this,varargin)
            %%get - this function gets the value of a given parameters
            %---PARAMETERS:
            %------0 INPUTS: Returns the value of all the parameters.
            %------1 - 13 INPUTS: Returns the value of the given
            %parameters.
            %---OUTPUT:
            %------1 OUTPUT: Struct containing the parameter values.
            
            parameters= struct;
            if(isempty(varargin))
                for i=1:this.nParameters
                    parameters.(this.propertiesNames{i})= this.(this.propertiesNames{i});
                end
            else
                for i=1:length(varargin)
                    parameterName= validatestring(varargin{i},this.propertiesNames); %autocomplete function
                    parameters.(parameterName) = this.(parameterName);
                end
            end
        end
        
        function steps= deg2steps(this,varargin)
            %%deg2step-- Use this function to pass from a given degrees to
            %%a number of steps. The input should be a vector containing
            %%all the degrees that should be transformed in to steps.
            if(length(varargin)== 1)
                steps= [];
                degrees= varargin{1};
                
                for i=1:length(degrees)
                    step= degrees(i)/this.degreesPerStep;
                    if(mod(step,1)~=0)
                        warning('The angle %.4f does not match with an integer number of steps. The closest match is %.0d steps, which corresponds to %.4f degrees.',degrees(i),round(step),round(step)*this.degreesPerStep); 
                    end
                    
                    steps= [steps round(step)];
                end
            else
                error('Please, enter a vector of the degrees you wish to convert');
            end
        end
        
        function degrees= steps2deg(this,varargin)
            %%step2deg-- Use this function to pass from a given number of
            %%steps to degrees. The input should be a vector containing all
            %%the steps that should be transformed in to degrees.
            if(length(varargin)== 1)
                degrees= [];
                steps= varargin{1};
                
                for i=1:length(steps)
                    if(mod(steps(i),1)~=0)
                        error('The number of steps have to be an integer. Please check all the numbers are integers.'); 
                    end
                    degree= steps(i)*this.degreesPerStep;
                    degrees= [degrees degree];
                end
            else
                error('Please, enter a vector of the degrees you wish to convert');
            end
        end
    end
    
    methods(Access= public)
        function newOrigin(this)
            %%newOrigin - Use this function to set the 0,0 position of the
            %%platform at the current position the platform is.
            this.originPosition= [0 0];
        end
        
        function home(this)
            %%go to the 0,0
            
            this.searchForLimit= 'True';
            
            %TO DO 
            this.rotateEngine(0,8010,'home');
            pause(0.5); %it could bounce, so pause a bit
            this.originPosition(1)= 0;
            this.searchForLimit= 'False';
            this.lastMove= 'Clockwise';
        end
        %----------------------PLATFORM CONTROL----------------------------
        function status= getEngineStatus(this,engine)
            %%getEngineStatus- Returns the status of a given Engine.
            %PARAMETERS:
            %   engine --> 0 or 1, depending if we want to rotate horizontal 
            %   or vertical.
            %OUTPUT: 
            %   Information about the engine status. (Such as temperature,
            %   voltage.. etc)
            
            %-----------------Information request querry-------------------:
            %   Byte1: Identificador dispositivo
            %   Byte2: Demanda de estado dinamico (RAM)
            %   Byte3: Carry return
            
            msg= '';
            %Byte 1
            msg= strcat(msg,num2str(engine));
            
            %Byte 2
            msg= strcat(msg,'D');
            
            %Carriage byte is not needed, because the fprintf functions
            %insert it by default.
            fprintf(this.connection,msg);          
            %disp(msg);
            
            %Movement response:
            %   Byte1: Device ID
            %   Byte2: Tipo mensaje(M from movement)
            %   Byte3: Error or result
            %   Byte4: Carry return
            
            %Lets get the response from the device
            response= fgetl(this.connection);
            %disp(response);
            status= struct;
            %Engine selected
            if(engine==0)
                status.Engine= 'horizontal';
            elseif(engine==1)
                status.Engine= 'vertical';
            else
                error('Engine not avaliable');
            end
            
            %validate answer
            if(double(response(2)) == 68)
            else
                error('Dynamic status answer not correct. An error happened.');
            end
            

            %Engine Status
            if(strcmp(response(3),'0'))
                status.Status= 'Stopped';
            elseif(strcmp(response(3),'1'))
                status.Status= 'Moving';
            else
                error('Something went wrong detecting the engine status.');
            end
            
            %System errors- to do
            
            %Current temperature
            temperature= double(response(5))-48; %substract 48 to convert from char to number
            status.CurrentTemperature= temperature;
            
            %Current voltage
            voltage= double(response(6))-48;%substract 48 to convert from char to number 
            status.CurrentVoltage= voltage;
            
            %Limit of movement reached?
            if(strcmp(response(7),'0'))
                status.LimitOfMovement= 'Not reached';
            elseif(strcmp(response(7),'1'))
                status.LimitOfMovement= 'Reached';
            else
                error('Something went wrong detecting if the limit of movement was reached.');
            end
        end
        
        function move(this,rotationEngines,varargin)
            %%move- moves the platform the degrees given
            %PARAMETERS:
            %---1 INPUT:
            %--------Vector of 2 elements:
            %------------Element1: Steps to move the platform horizontally.
            %------------Element2: Steps to move the platform vertically.
            %---2 INPUTS:
            %--------Input1: 
            %------------Vector of 2 elements:
            %----------------Element1: Steps to move the platform horizontally.
            %----------------Element2: Steps to move the platform vertically.
            %--------Input2: String determining wether if the movement is 
            %absolute or relative. ('Absolute' or 'Relative')
            %---3 INPUTS:
            %--------Input1: 
            %------------Vector of 2 elements:
            %----------------Element1: Steps to move the platform horizontally.
            %----------------Element2: Steps to move the platform vertically.
            %--------Input2: String determining wether if the movement is 
            %absolute or relative. ('Absolute' or 'Relative')
            %--------Input3: Vector of 3 values: 1rst is rotationSpeed, 2nd
            %is accelerationSteps, and 3rd is decelerationSteps. For
            %example, for 30 rpm, 100 accleration steps,200 deceleration steps a
            %relative move of 90 and 18 degrees, the input would be: 
            %move(deg2step([90 18]),'Relative',[30,100,200])
            if(length(rotationEngines) ~= 2)
                error('The first input should be a vector containing the steps that each engine should move. It should be a vector of length 2.')
            end
            rotationEngine0= rotationEngines(1);
            rotationEngine1= rotationEngines(2);
            this.refreshParameters();
            if(isempty(varargin)) %no 3rd input entered, just move and record the move.
                this.rotateEngine(0,rotationEngine0);
                this.rotateEngine(1,rotationEngine1);
                this.originPosition= [this.originPosition(1)-rotationEngine0 this.originPosition(2)-rotationEngine1];
                
            elseif(length(varargin) >= 1) %2 or 3 inputs entered
                if(length(varargin) == 2)
                    this.rotationSpeed= varargin{2}(1);
                    this.acelerationSteps= varargin{2}(2);
                    this.decelerationSteps = varargin{2}(3);
                end
                if (strcmp(varargin{1},'Absolute'))
                    correctedAngle0= rotationEngine0+this.originPosition(1);
                    correctedAngle1= rotationEngine1+this.originPosition(2);
                    this.rotateEngine(0,correctedAngle0);
                    this.rotateEngine(1,correctedAngle1);
                    this.originPosition= [this.originPosition(1)-correctedAngle0 this.originPosition(2)-correctedAngle1];
                 if(this.originPosition(1)>=8000 || this.originPosition(1)<=-8000)
                     this.originPosition(1) = rem(this.originPosition(1),8000);
                 end
                    
                elseif(strcmp(varargin{1},'Relative'))
                    this.rotateEngine(0,rotationEngine0);
                    this.rotateEngine(1,rotationEngine1);
                    this.originPosition= [this.originPosition(1)-rotationEngine0 this.originPosition(2)-rotationEngine1];
                else
                    error('3rd input was incorrect. It can be only Absolute or Relative');
                end
            else
                error('Number of parameters not correct. Only 1,2 or 3 inputs are supported');
            end
            %disp(length(varargin));
        end
    end
   
    methods(Access= private)
        
        function rotateEngine(this,engine,steps,varargin)
            %%ROTATE- Rotates the engine the degrees given
            %PARAMETERS:
            %   engine --> 0 or 1, depending if we want to rotate horizontal or vertical.
            %   degrees --> degrees we want to rotate.
            %OUTPUT: 
            %   O output
            
            %first, check if the number of degreees is negative
            negative= false;
            if(steps <0)
                negative= true;
            end
            steps= abs(steps);
            
            
            %Now we know the steps the engine should do. We can start
            %preparing the message to be sent. The format is the following:
            
            %Movement missage:
            %   Byte1: Device ID
            %   Byte2: Tipo mensaje (M from movement)
            %   Bytes 3-8: Steps to be done
            %   Byte9: Rotation Direction
            %   Bytes 10-12: Pasos pendiente aceleracion
            %   Bytes 13-15: Pasos pendiente deaceleracion
            %   Bytes 16-18: Movement speed
            %   Byte 19: Selector micropasos y tipo de motor
            %   Byte 20: Stop current
            %   Byte 21: Search for limit
            %   Byte 22: Continous movement
            %   Byte 23: Answer when movement finished
            %   Byte 24: Carry return
            
            msg= '';
            %Byte 1
            msg= strcat(msg,num2str(engine));
            
            %Byte 2
            msg= strcat(msg,'M');
            
            %Process the direction of rotation
            if(strcmp(this.positiveDirectionOfRotation,'Clockwise'))
                if(negative)
                    if(strcmp(this.lastMove,'Clockwise'))
                        changeOfDirection= true;
                    else
                        changeOfDirection= false;
                    end
                    rotation= 'L';
                else
                    if(strcmp(this.lastMove,'Clockwise'))
                        changeOfDirection= false;
                    else
                        changeOfDirection= true;
                    end
                    rotation= 'R';
                    
                end
            
            elseif(strcmp(this.positiveDirectionOfRotation,'AntiClockwise'))
                if(negative)
                    if(strcmp(this.lastMove,'Clockwise'))
                        changeOfDirection= false;
                    else
                        changeOfDirection= true;
                    end
                    rotation= 'R';
                    %msg= strcat(msg,'R');
                else
                    if(strcmp(this.lastMove,'Clockwise'))
                        changeOfDirection= true;
                    else
                        changeOfDirection= false;
                    end
                    rotation= 'L';
                    %msg= strcat(msg,'L');
                end
                
            else
                error('The value set in the parameter directionOfRotation should be either Clockwise or AntiClockwise. Please check it.');
            end
            
            if(changeOfDirection && engine== 0) %%if a change of direction has happened in the engine 0, we should add aditional steps.
                steps= steps+ this.changeDirectionCorrection;
                if(strcmp(this.lastMove,'Clockwise'))
                    this.lastMove= 'AntiClockwise';
                else
                    this.lastMove= 'Clockwise';
                end
            end
            
            %Bytes 3-8
            step= sprintf('%06d',steps); %format the data 
            step= fliplr(step);%flip the data to match with data frame expected
            msg= strcat(msg,step);
            
            %Byte 9
            msg= strcat(msg,rotation);
            
            %Bytes 10-12
            accelerationSteps=this.acelerationSteps;
            if(steps< this.acelerationSteps || steps <this.decelerationSteps)
                accelerationSteps= floor(steps*this.smallStepsAcelerationRatio);
            end
            accelerationStep= sprintf('%03d',accelerationSteps); %format the data
            accelerationStep= fliplr(accelerationStep);%flip the data to match with data frame expected
            msg= strcat(msg,accelerationStep);
            
            stepsDeceleration= this.decelerationSteps;
            %Bytes 13-15
            if(steps< this.decelerationSteps)
                stepsDeceleration= floor(steps*this.smallStepsDecelerationRatio);
            end
            decelerationStep= sprintf('%03d',stepsDeceleration); %format the data
            decelerationStep= fliplr(decelerationStep);%flip the data to match with data frame expected
            msg= strcat(msg,decelerationStep);
            
            %Bytes 16-18
            movementSpeed= sprintf('%03d',this.rotationSpeed);
            movementSpeed= fliplr(movementSpeed);%flip the data to match with data frame expected
            msg= strcat(msg,movementSpeed);
            
            %Byte 19
            if(this.stepsForCompleteRotation == 200 ) 
                if(strcmp(this.stepType,'Full Steps'))
                    msg= strcat(msg,'1');
                elseif(strcmp(this.stepType,'Half Steps'))
                    msg= strcat(msg,'2');
                elseif(strcmp(this.stepType,'16 microSteps'))
                    msg= strcat(msg,'3');
                elseif(strcmp(this.stepType,'32 microSteps'))
                    msg= strcat(msg,'4');
                elseif(strcmp(this.stepType,'64 microSteps'))
                    msg= strcat(msg,'5');
                else
                    error(['The value set in the parameter stepsType should be either Full Steps, Half Steps,' ...
                    '16 microSteps, 32 microSteps or 64 microSteps. Please check it.']);
                end
            elseif(this.stepsForCompleteRotation == 400 )
                if(strcmp(this.stepType,'Full Steps'))
                    msg= strcat(msg,'A');
                elseif(strcmp(this.stepType,'Half Steps'))
                    msg= strcat(msg,'B');
                elseif(strcmp(this.stepType,'16 microSteps'))
                    msg= strcat(msg,'C');
                elseif(strcmp(this.stepType,'32 microSteps'))
                    msg= strcat(msg,'D');
                elseif(strcmp(this.stepType,'64 microSteps'))
                    msg= strcat(msg,'E');
                else
                    error(['The value set in the parameter stepsType should be either Full Steps, Half Steps,' ...
                    '16 microSteps, 32 microSteps or 64 microSteps. Please check it.']);
                end
            else
                error('The value set in the parameter stepsForCompleteRotation should be either 200 or 400. Please check it.');
            end
            
            %Byte 20 
            if(strcmp(this.stopCurrent,'15%'))
                msg= strcat(msg,'0');
            elseif(strcmp(this.stopCurrent,'40%'))
                msg= strcat(msg,'1');
            elseif(strcmp(this.stopCurrent,'55%'))
                msg= strcat(msg,'2');
            elseif(strcmp(this.stopCurrent,'75%'))
                msg= strcat(msg,'3');
            else
                error('The value set in the parameter stopCurrent should be either 15%, 40%, 55% or 75%. Please check it.');
            end
            
            %Byte 21
            if(strcmp(this.searchForLimit,'False'))
                msg= strcat(msg,'0');
            elseif(strcmp(this.searchForLimit,'True'))
                msg= strcat(msg,'1');
            else
                error('The value set in the parameter searchForLimit should be either True or False. Please check it.');
            end
            
            %Byte 22
            if(strcmp(this.continousMovement,'False'))
                msg= strcat(msg,'0');
            elseif(strcmp(this.continousMovement,'True'))
                msg= strcat(msg,'1');
            else
                error('The value set in the parameter continousMovement should be either True or False. Please check it.');
            end
            
            %Byte 23
            if(strcmp(this.searchForLimit,'False'))
                msg= strcat(msg,'0');
            elseif(strcmp(this.searchForLimit,'True'))
                msg= strcat(msg,'1');
            else
                error('The value set in the parameter waitForMoveToFinish should be either True or False. Please check it.');
            end
            
            %Carriage byte is not needed, because the fprintf functions
            %insert it by default.
            fprintf(this.connection,msg);          
            %disp(msg);
            
            %Movement response:
            %   Byte1: Device ID
            %   Byte2: Tipo mensaje(M from movement)
            %   Byte3: Error or result
            %   Byte4: Carry return
            
            %Lets get the response from the device

            response= fgetl(this.connection);
            if(double(response(3))== 6)
                %Acknowledge
                %disp('Acknowledge received.');
            elseif(double(response(3))== 15)
                %Not Acknowledge
                error('Acknowledge not received. Error in comunication with platform.');
            elseif(double(response(3)) == 121)
                %Limit of movement reached
                disp('Position 0 reached.');
            elseif(double(response(3)) == 122)
                %Movement finished
                %disp('Movement finished');
            else
                error('Response not recognized. Unknown error.');
            end
            
            if(~isempty(varargin))
                if(strcmp(varargin{1},'home'))
                %if the user is searching for home, we have to read the
                %response from the device twice.
                    response= [];
                    warning('off','all')
                    while(isempty(response))
                        response= fgetl(this.connection);
                    end
                    warning('on','all')
                    if(double(response(3))== 6)
                        %Acknowledge
                        %disp('Acknowledge received.');
                    elseif(double(response(3))== 15)
                        %Not Acknowledge
                        error('Acknowledge not received. Some error happened.');
                    elseif(double(response(3)) == 121)
                        %Limit of movement reached
                        %disp('Position 0 reached.');
                    elseif(double(response(3)) == 123)
                        %Movement finished
                        warning('Movement finished and home was not reached. Something is wrong with the sensor. Please check that it connected and set properly.');
                    else
                        error('Response not recognized. Unknown error.');
                    end
                end
            end
            
            if(strcmp(this.waitForMoveToFinish,'True') && steps ~= 0)
%                 stepsPerSecond= this.rotationSpeed*(360/60)/(40*this.degreesPerStep);
%                 meanVelocityAccelerating= stepsPerSecond/1.5;
%                 stepsAcelerating= accelerationStep;
%                 secondsAc= stepsAcelerating/meanVelocityAccelerating;
%                 pause(secondsAc);
%                 stepsDecelerating= decelerationStep;
%                 secondsDec= stepsDecelerating/meanVelocityAccelerating;
%                 pause(secondsDec);
%                 seconds= (steps-stepsAcelerating-stepsDecelerating)/stepsPerSecond;              
%                 pause(seconds);
                
                moveNotFinished= 1;
                while(moveNotFinished)
                    status= this.getEngineStatus(engine);
                    if(strcmp(status.Status,'Stopped') )
                        moveNotFinished= 0;
                    else
                        pause(0.5);
                    end
                end
            end

            %disp(response);
            
        end
                
        function refreshParameters(this,engine)
            %%Refresh parameters info
            %------------------------Connection querry----------------------:
            %   Byte1: Identificador dispositivo
            %   Byte2: Tipo mensaje
            %   Byte3: Nivel Corriente
            %   Byte4: Modo Dispositivo  
            %   Byte5: Identificador dispositivo modo serie
            %   Byte6: Reservado
            %   Byte7: Carry return
           
           msg= [];
           %Byte1
           msg= strcat(msg,'0');
           
           %Byte2
           msg= strcat(msg,'Q');
           
           %Byte3
           if (this.maximumCurrent >= 1 && this.maximumCurrent <= 200)
               msg= strcat(msg,char(48+this.maximumCurrent));
           else
               error('The value set in the parameter maximumCurrent should be between 10 and 200. Please check it.');
           end
           
           %Byte4
           if (strcmp(this.deviceMode,'Serie'))
               msg= strcat(msg,'S');
           elseif(strcmp(this.deviceMode,'Enable'))
               msg= strcat(msg,'E');
           elseif(strcmp(this.deviceMode,'Track'))
               msg= strcat(msg,'T');
           elseif(strcmp(this.deviceMode,'Special'))
               msg= strcat(msg,'P');
           else
               error('The value set in the parameter deviceMode should be either Serie, Enable, Track or Special. Please check it');
           end   
           
           %Byte5
           msg = strcat(msg,'0');
           
           %Byte6
           msg= strcat(msg,'0');

           %Carriage byte is not needed, because the fprintf functions
           %insert it by default.
           fprintf(this.connection,msg);
           
           %-----------------------Connection Response--------------------
            %   Byte1: Identificador dispositivo
            %   Byte2: Tipo mensaje
            %   Byte3: Nivel Corriente
            %   Byte4: Modo Dispositivo  
            %   Byte5: Identificador dispositivo modo serie
            %   Byte6: Reservado
            %   Byte7: Reservado
            %   Byte8: Carry return
            
           %Lets get the response from the device
           response= fgetl(this.connection);
           
                       %%Refresh parameters info
            %------------------------Connection querry----------------------:
            %   Byte1: Identificador dispositivo
            %   Byte2: Tipo mensaje
            %   Byte3: Nivel Corriente
            %   Byte4: Modo Dispositivo  
            %   Byte5: Identificador dispositivo modo serie
            %   Byte6: Reservado
            %   Byte7: Carry return
           
           msg= [];
           %Byte1
           msg= strcat(msg,'1');
           
           %Byte2
           msg= strcat(msg,'Q');
           
           %Byte3
           if (this.maximumCurrent >= 1 && this.maximumCurrent <= 200)
               msg= strcat(msg,char(126));
           else
               error('The value set in the parameter maximumCurrent should be between 10 and 200. Please check it.');
           end
           
           %Byte4
           if (strcmp(this.deviceMode,'Serie'))
               msg= strcat(msg,'S');
           elseif(strcmp(this.deviceMode,'Enable'))
               msg= strcat(msg,'E');
           elseif(strcmp(this.deviceMode,'Track'))
               msg= strcat(msg,'T');
           elseif(strcmp(this.deviceMode,'Special'))
               msg= strcat(msg,'P');
           else
               error('The value set in the parameter deviceMode should be either Serie, Enable, Track or Special. Please check it');
           end   
           
           %Byte5
           msg = strcat(msg,'1');
           
           %Byte6
           msg= strcat(msg,'0');

           %Carriage byte is not needed, because the fprintf functions
           %insert it by default.
           fprintf(this.connection,msg);
           
           %-----------------------Connection Response--------------------
            %   Byte1: Identificador dispositivo
            %   Byte2: Tipo mensaje
            %   Byte3: Nivel Corriente
            %   Byte4: Modo Dispositivo  
            %   Byte5: Identificador dispositivo modo serie
            %   Byte6: Reservado
            %   Byte7: Reservado
            %   Byte8: Carry return
            
           %Lets get the response from the device
           response= fgetl(this.connection);
        end
        
        end
        
  
end

