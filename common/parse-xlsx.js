let fs = require('fs');
let addreses = []
const hre = require("hardhat");
let xlsx = require('node-xlsx');
const excelFilePath = 'whitelist.xlsx'
const sheets = xlsx.parse(excelFilePath);
sheets.forEach(function(sheet){
    // console.log(sheet['name']);//sheet1
    // rade every row content
    let num=0;
    sheet['data'].shift();
    try {
        for(var rowId in sheet['data']){
            num++;
            var row=sheet['data'][rowId];
            console.log(num,'=======',row[7].length)
            if(row[7].length ==42){
                const res = hre.ethers.utils.getAddress(row[7]);
                addreses.push(res)
            };
        }
    } catch (error) {
        
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

var addressCollection = group(newArr, 500);

 let [arr1,arr2,arr3,arr4,arr5,arr6] =[addressCollection[0],addressCollection[1],addressCollection[2],addressCollection[3],addressCollection[4],addressCollection[5]];

 let replace1,replace2,replace3,replace4,replace5,replace6;

 arr1 = arr1.map(item=>item = "\"\ " +item + '\"\ \r')
 arr2 = arr2.map(item=>item = "\"\ " +item + '\"\ \r')
 arr3 = arr3.map(item=>item = "\"\ " +item + '\"\ \r')
 arr4 = arr4.map(item=>item = "\"\ " +item + '\"\ \r')
 arr5 = arr5.map(item=>item = "\"\ " +item + '\"\ \r')
 arr6 = arr6.map(item=>item = "\"\ " +item + '\"\ \r')


 replace1 = 'module.exports.whitelist1 = [\n' + arr1 + '\r]';
 replace2 = '\r\rmodule.exports.whitelist2 = [\n' + arr2 + '\r]';
 replace3 = '\r\rmodule.exports.whitelist3 = [\n' + arr3 + '\r]';
 replace4 = '\r\rmodule.exports.whitelist4 = [\n' + arr4 + '\r]';
 replace5 = '\r\rmodule.exports.whitelist5 = [\n' + arr5 + '\r]';
 replace6 = '\r\rmodule.exports.whitelist6 = [\n' + arr6 + '\r]';


let newFile = replace1+replace2+replace3+replace4+replace5+replace6;
console.log("=====arr1======",arr1.length);
console.log("=====arr2======",arr2.length);
console.log("=====arr3======",arr3.length);
console.log("=====arr4======",arr4.length);
console.log("=====arr4======",arr5.length);
console.log("=====arr4======",arr6.length);


let fd = fs.openSync(__dirname + '/whitelist.js',"w");
fs.writeFileSync(fd, newFile, 'utf8');