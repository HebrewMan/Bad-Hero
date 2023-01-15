let fs = require('fs');
let addreses = []

let xlsx = require('node-xlsx');
const excelFilePath = 'whitelist.xlsx'
const sheets = xlsx.parse(excelFilePath);
sheets.forEach(function(sheet){
    // console.log(sheet['name']);//sheet1
    // rade every row content
    for(var rowId in sheet['data']){
        var row=sheet['data'][rowId];
        if(row[7].length==42)addreses.push(row[7]);    
    }
});


let newArr = addreses.filter((item, index) => addreses.indexOf(item) === index); 
console.log("======== length before filter ========",addreses.length);
console.log("======== length after filter ========",newArr.length);

function group(array, subGroupLength) {
    var index = 0;
    var newArray = [];
    while(index < array.length) {
        newArray.push(array.slice(index, index += subGroupLength));
    }
    return newArray;
}

var addressCollection = group(newArr, 700);

 let [arr1,arr2,arr3,arr4] =[addressCollection[0],addressCollection[1],addressCollection[2],addressCollection[3]];

 let replace1,replace2,replace3,replace4;

 arr1 = arr1.map(item=>item = "\"\ " +item + '\"\ \r')
 arr2 = arr2.map(item=>item = "\"\ " +item + '\"\ \r')
 arr3 = arr3.map(item=>item = "\"\ " +item + '\"\ \r')
 arr4 = arr4.map(item=>item = "\"\ " +item + '\"\ \r')

 replace1 = 'export const whitelist1 = [\n' + arr1 + '\r]';
 replace2 = '\r\rexport const whitelist2 = [\n' + arr2 + '\r]';
 replace3 = '\r\rexport const whitelist3 = [\n' + arr3 + '\r]';
 replace4 = '\r\rexport const whitelist4 = [\n' + arr4 + '\r]';

let newFile = replace1+replace2+replace3+replace4;
console.log("=====arr1======",arr1.length);
console.log("=====arr2======",arr2.length);
console.log("=====arr3======",arr3.length);
console.log("=====arr4======",arr4.length);

let fd = fs.openSync(__dirname + '/whitelist.js',"w");
fs.writeFileSync(fd, newFile, 'utf8');