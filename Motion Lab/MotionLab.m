function [ dataY, timeX ] = MotionLab( ) % ip, port )
%MOTIONLAB, motion port server for matlab
%   The Motion Port App will transmit data to this func

port = 8080;

packnum = 100;
indexArray = zeros(1,packnum);
dataArray = zeros(3,packnum);
x = zeros(1,packnum + 1);
v = zeros(1,packnum + 1);
dataArray(:,:) = nan;
packsize = 4; % for (ax, ay, az) the packsize = 3

% echoudp('on', 8081);
udpObj = udp('192.168.191.255', 8081); % broadcast IP
set(udpObj, 'InputBufferSize', 4096);
set(udpObj, 'LocalPort', port); % the port for udp to receive data
set(udpObj, 'ByteOrder', 'littleEndian');

fopen(udpObj);
% % head = single(3.14159); freq = 50; packnum = 60;
% % fwrite(udpObj, 'hello'); %[head, freq, packnum], 'float');
% [str, count, msg, gramaddr, gramport] = fread(udpObj, 1);
% if count > 0 
%     disp(['received from addr: ' gramaddr ' port: ' num2str(gramport)]);
%     set(udpObj, 'RemoteHost', gramaddr);
%     fwrite(udpObj, 'hello');
% else 
%     disp('failed');
%     fclose(udpObj);
%     return
% end

errorCount = 0;

try 
    while 1
        % get index
        [index,count,msg,datagramaddress,datagramport] = fread(udpObj, 1, 'int32');
        if count ~= 1
            if ~isempty(msg)
                disp(['Error (count=' num2str(count) '): '  msg]);
                errorCount = errorCount + 1;
                if errorCount >= 2
                    break;
                end
                disp(['pause for ' num2str(errorCount) ' seconds']);
                pause(errorCount);
            end
            flushinput(udpObj);
            continue
        elseif index == -1
            disp('Client closed.');
            break;
        else
            errorCount = 0;
        end
        disp(['received data from ' datagramaddress ': ' num2str(datagramport)]);
        
        % get data size
        [sizeOfData, count] = fread(udpObj, 1, 'int32');
        if count~=1
            disp(['error when get data size: count = ' num2str(count)]);
            flushinput(udpObj);
            continue
        else
            disp(['data size: ' num2str(sizeOfData) ' pack num: ' num2str(sizeOfData/packsize)]);
        end
        if sizeOfData/packsize ~= packnum
            packnum = sizeOfData/packsize;
            indexArray = zeros(1,packnum);
            dataArray = zeros(3,packnum);
            x = zeros(1,packnum + 1);
            v = zeros(1,packnum + 1);
        end
        
        % get data
        [data, count] = fread(udpObj,sizeOfData,'float');
        if count~=sizeOfData
            disp(['data count error: ' num2str(count) ' expected: ' num2str(sizeOfData)]);
            flushinput(udpObj);
            continue
        end
        % fwrite(udpObj,'hello');
        disp(['received: [' num2str(index - sizeOfData/packsize+1) '~' num2str(index) '] ']); % num2str(data')]);
        for i = 1:(sizeOfData/packsize) 
            indexArray = [indexArray(2:end), data(1 + (i-1)*packsize)]; %index - (sizeOfData/packsize - i)];
            dataArray  = [dataArray(:,2:end), data((2:4) + (i-1)*packsize)];
        end
        % calcluations 
        dataM = getDataM(dataArray, 0.14973);
        [x,v] = getXV(dataM, [x(:,end),v(:,end)], indexArray);
        subplot(2,2,1); % 1
        plot(v');
        axis tight
        title speed
        subplot(2,2,2); % 2
        plot(indexArray, dataArray);
        axis tight
        title acceleration
        subplot(2,2,3); % 3
        plot(x');
        title location
        subplot(2,2,4); % 4
        plotRout(x(1,:),x(2,:),x(3,:));
        hold on
        % draw
%         plot(indexArray, dataArray);
%         axis tight
        drawnow
        
        if sizeOfData/packsize > 10 
            pause(0.5) % wait for data ready
        end
    end
catch e
    disp(e)
    fclose(udpObj);
end
% echoudp('off');
fclose(udpObj);


dataY = dataArray;
timeX = indexArray;

end

