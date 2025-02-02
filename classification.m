% Eliminar %{ y su correspondiente %} si se va a usar por primera vez o se
% desea reentrenar la CNN. Si está satisfecho con el entrenamiento del modelo
% y las variables se encuentran en el Workspace, puede comentariar de nuevo
% toda la sección de código hasta la linea "Evaluacion con una imagen
% cualquiera" para que la compilacion sea más rápida.

%{


%Carpetas donde se encuentran las imagenes a utilizar en la CNN
outputFolder = fullfile('Datos');
rootFolder = fullfile(outputFolder,'Etiquetas');

%Se definen las categorias, clases o etiquetas en las cuales una imagen
%será clasificada
categories = {'Aprovechable','No_aprovechable','Organico_biodegradable', ...
    'Residuo_especial','Residuo_peligroso'};

imds = imageDatastore(fullfile(rootFolder,categories),'LabelSource','foldernames');

tbl = countEachLabel(imds);
minSetCount = min(tbl{:,2});

%Se configuran cada una de las etiquetas con igual numero de imagenes
imds = splitEachLabel(imds,minSetCount,'randomize');
%countEachLabel(imds);

%{
aprovechable = find(imds.Labels == 'Aprovechable',1);
no_aprovechable = find(imds.Labels == 'No_aprovechable',1);
organico_biodegradable = find(imds.Labels == 'Organico_biodegradable',1);
residuo_especial = find(imds.Labels == 'Residuo_especial',1);
residuo_peligroso = find(imds.Labels == 'Residuo_peligroso',1);

figure
subplot(2,3,1);
imshow(readimage(imds,aprovechable));
subplot(2,3,2);
imshow(readimage(imds,no_aprovechable));
subplot(2,3,3);
imshow(readimage(imds,organico_biodegradable));
subplot(2,3,4);
imshow(readimage(imds,residuo_especial));
subplot(2,3,5);
imshow(readimage(imds,residuo_peligroso));
%} 


net = resnet50();
% figure
% plot(net)
% title('Arquitectura de modelo pre-entrenado ResNet')
% set(gca, 'YLim',[150 170]);

%net.Layers(1);

[trainingSet,testSet] = splitEachLabel(imds,0.3,'randomize');
imageSize = net.Layers(1).InputSize;

augmentedTrainingSet = augmentedImageDatastore(imageSize, ...
    trainingSet, 'ColorPreprocessing', 'gray2rgb');

augmentedTestSet = augmentedImageDatastore(imageSize, ...
    testSet, 'ColorPreprocessing', 'gray2rgb');

w1 = net.Layers(2).Weights;
w1 = mat2gray(w1);

% figure
% montage(w1);
% title('Peso de primera capa convolucional')

featureLayer = 'fc1000';

trainingFeatures = activations(net, ...
    augmentedTrainingSet,featureLayer, 'MiniBatchSize',32,'OutputAs','columns');

trainingLabels = trainingSet.Labels;

classifier = fitcecoc(trainingFeatures,trainingLabels, ...
    'Learner', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'columns' );

testFeatures = activations(net, ...
    augmentedTestSet,featureLayer, 'MiniBatchSize',32,'OutputAs','columns');

predictLabels = predict( classifier , testFeatures, 'ObservationsIn', 'columns');

testLabels = testSet.Labels;
confMat = confusionmat(testLabels, predictLabels);
confMat = bsxfun(@rdivide, confMat, sum(confMat,2));

%Precicision del modelo
precisionModelo = mean(diag(confMat));



%}



% -------- // Evaluacion con una imagen cualquiera // ----------

nuevaImagen = imread(fullfile('img5.jpg'));

imgProcesada =  augmentedImageDatastore(imageSize, ...
    nuevaImagen, 'ColorPreprocessing', 'gray2rgb');

caracteristicaImg = activations(net, ...
    imgProcesada,featureLayer, 'MiniBatchSize',32,'OutputAs','columns');

[etiqueta,score] =  predict( classifier , caracteristicaImg, 'ObservationsIn', 'columns');
maxProb = max(score)+1;

textoResultado = sprintf('La imagen analizada corresponde a la etiqueta:  %s', etiqueta);

%Ventana para muestra de resultados
textoResultado = replace(textoResultado,"_"," ");


if strcmp(char(etiqueta(1)),'Aprovechable')
    consejo = ['Estos residuos deben ser recogidos y llevados a una \n'... 
        ' Estación  de Clasificación y Aprovechamiento –ECA'];
elseif strcmp(char(etiqueta(1)),'No_aprovechable')
    consejo = ['Deberán ser entregados al prestador del servicio \n'...
        'de NO APROVECHABLES e irán al relleno sanitario.'];
elseif strcmp(char(etiqueta(1)),'Organico_biodegradable')
    consejo = ['Estos residuos son usados para Abonos orgánicos, \n'...
        'compostaje y lombricultura, de acuerdo a la guia para el aprovechamiento\n'...
        ' de residuos organicos de la UAESP.'];
elseif strcmp(char(etiqueta(1)),'Residuo_especial')
    consejo = ['Estos residuos deben ser tratados de acuerdo a la \n '...
        'resolución 2309 del 24 de febrero del 86.'];
elseif strcmp(char(etiqueta(1)),'Residuo_peligroso')
    consejo = ['Para la disposición final se tiene como opciones la \n '...
        'celda de seguridad, relleno de seguridad y otros, de acuerdo a \n'...
        ' la normativa RESPEL.'];
else
    consejo = 'No se encontró consejo para el tipo de residuo.';
end

image(nuevaImagen);
title({(textoResultado);['Probabilidad: ', num2str(maxProb),' '];['Consejo: ', sprintf(consejo),' '];(' ')});

