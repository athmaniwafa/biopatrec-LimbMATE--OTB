function [wrist_pronation, wrist_flexion, finger_extension] = AcceleTest(comPort)
    
    glove = AcceleGlove(comPort);
    if glove.status == AcceleGlove.ERROR
        return;
    end
    
    x                   = linspace(0,9.8,50);
    wrist_pronation     = zeros(1,50);
    wrist_flexion       = zeros(1,50);
    finger_extension    = zeros(1,50);
    
    figure(1);
    subplot(3,1,1);
    h1 = plot(x,wrist_pronation);
    title('Wrist Pronation');
    ylim([-180,180]);
    
    subplot(3,1,2);
    h2 = plot(x,wrist_flexion);
    title('Wrist Flexion');
    ylim([-180,180]);
    
    subplot(3,1,3);
    h3 = plot(x,finger_extension);
    title('Finger Flexion');
    ylim([-180,180]);
    
    glove.start_acquisition();
    if glove.status == AcceleGlove.ERROR
        return;
    end
    
    for ii = 1:50
        tic();
        glove.update();
        if glove.status == AcceleGlove.ERROR
            return;
        end
        
        while (glove.sample_ready == 0) || (toc() < 0.5)
        end
        
        wrist_pronation(ii)     = glove.get_wrist_pronation();
        wrist_flexion(ii)       = glove.get_wrist_flexion();
        finger_extension(ii)    = glove.get_finger_flexion();

        set(h1,'XData',x,'YData',wrist_pronation);
        set(h2,'XData',x,'YData',wrist_flexion);
        set(h3,'XData',x,'YData',finger_extension);
        
        drawnow;
    end
%     for ii = 1:50
%         glove = glove.update();
%         if glove.status == AcceleGlove.ERROR
%             return;
%         end
%         
%         wrist_pronation(ii)     = glove.get_wrist_pronation();
%         wrist_flexion(ii)       = glove.get_wrist_flexion();
%         finger_extension(ii)    = glove.get_finger_flexion();
% 
%         set(h1,'XData',x,'YData',wrist_pronation);
%         set(h2,'XData',x,'YData',wrist_flexion);
%         set(h3,'XData',x,'YData',finger_extension);
%         
%         pause(0.001); % Dummy value to ensure plotting occurs
%     end
    
    glove.stop_acquisition();
end

function Serial_OnDataReceived(glove, hs, endCheck)
    if glove.status == AcceleGlove.ERROR
        return;
    end
    
    wrist_pronation(glove.update_count+1)     = glove.get_wrist_pronation();
    wrist_flexion(glove.update_count+1)       = glove.get_wrist_flexion();
    finger_extension(glove.update_count+1)    = glove.get_finger_flexion();
    fprintf("%f\n", wrist_pronation(glove.update_count+1));
    
    set(hs(1),'YData',wrist_pronation);
    set(hs(2),'YData',wrist_flexion);
    set(hs(3),'YData',finger_extension);
    drawnow;
    
    if glove.update_count >= endCheck
        glove.stop_acquisition();
    else
        glove.update();
    end
end
