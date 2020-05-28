outputFolder = fullfile('Datos');
rootFolder = fullfile(outputFolder,'Etiquetas');

categories = {'Aprovechable','No_aprovechable','Organico_biodegradable','Residuo_especial','Residuo_peligroso'};
imds = imageDatastore(fullfile(rootFolder,categories),'LabelSource','foldernames');

tbl = countEachLabel(imds);
minSetCount = min(tbl{:,2});

%Se configuran cada una de las etiquetas con igual numero de imagens
imds = splitEachLabel(imds,minSetCount,'randomize');
countEachLabel(imds);


aprovechable = find(imds.Labels == 'Aprovechable',1);
no_aprovechable = find(imds.Labels == 'No_aprovechable',1);
organico_biodegradable = find(imds.Labels == 'Organico_biodegradable',1);
residuo_especial = find(imds.Labels == 'Residuo_especial',1);
residuo_peligroso = find(imds.Labels == 'Residuo_peligroso',1);

% figure
% subplot(2,3,1);
% imshow(readimage(imds,aprovechable));
% subplot(2,3,2);
% imshow(readimage(imds,no_aprovechable));
% subplot(2,3,3);
% imshow(readimage(imds,organico_biodegradable));
% subplot(2,3,4);
% imshow(readimage(imds,residuo_especial));
% subplot(2,3,5);
% imshow(readimage(imds,residuo_peligroso));


net = resnet50();
% figure
% plot(net)
% title('Arquitectura de modelo pre-entrenado ResNet')
% set(gca, 'YLim',[150 170]);

net.Layers(1);

[trainingSet,testSet] = splitEachLabel(imds,0.3,'randomize');
imageSize = net.Layers(1).InputSize;

augmentedTrainingSet = augmentedImageDatastore(imageSize, ...
    trainingSet, 'ColorPreprocessing', 'gray2rgb');

augmentedTestSet = augmentedImageDatastore(imageSize, ...
    testSet, 'ColorPreprocessing', 'gray2rgb');

w1 = net.Layers(2).Weights;
w1 = mat2gray(w1);

figure
montage(w1);
title('Peso de primera capa convolucional')








