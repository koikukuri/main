function doPost(e) {
  try {
    const payload = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("プロフィール"); 

    if (!sheet) { 
      throw new Error("指定されたシート（プロフィール）が見つかりません。"); 
    }
    
    let fileBlob = null;

    // Base64形式の画像データがあるかチェック
    if (payload.fileData) {
      const [meta, base64] = payload.fileData.split(',');
      const mimeType = meta.split(';')[0].split(':')[1];
      const decodedData = Utilities.base64Decode(base64);
      fileBlob = Utilities.newBlob(decodedData, mimeType, payload.fileName);
    }
    
    // --- ▼▼▼ ユーザーを検索し、更新または新規追加するロジック ▼▼▼ ---
    const data = sheet.getDataRange().getValues();
    const lineUserIdToFind = payload.lineUserId;
    let userRow = -1;

    // 1行目はヘッダーと仮定し、2行目から検索
    for (let i = 1; i < data.length; i++) {
      if (data[i][1] === lineUserIdToFind) { // B列(インデックス1)のLINE User IDをチェック
        userRow = i + 1; // 実際のシートの行番号を取得
        break;
      }
    }

    // 新しく登録するデータの配列を作成 (画像URLはなし)
    const newRowData = [
      new Date(),           // 登録日時
      payload.lineUserId,   // LINE User ID
      payload.nickname,     // ニックネーム
      payload.age,          // 年齢
      payload.gender,       // 性別
      payload.occupation,   // 職業
      payload.hobbies,      // 趣味
      payload.introduction  // 自己紹介
    ];

    if (userRow !== -1) {
      // --- ユーザーが見つかった場合：既存の行を更新 ---
      sheet.getRange(userRow, 1, 1, newRowData.length).setValues([newRowData]);
    } else {
      // --- ユーザーが見つからなかった場合：新しい行として追加 ---
      sheet.appendRow(newRowData);
    }
    // --- ▲▲▲ 更新または新規追加ロジックここまで ▲▲▲ ---

    // --- ▼▼▼ メール通知機能 ▼▼▼ ---
    const recipient = "kawai@coconazo.com";
    const subject = "【Koi-Kukuri】新規プロフィール登録がありました";
    const htmlBody = `
      <h2>新規プロフィール登録がありました</h2>
      <p><strong>ニックネーム:</strong> ${payload.nickname || '未入力'}</p>
      <p><strong>年齢:</strong> ${payload.age || '未入力'}</p>
      <p><strong>性別:</strong> ${payload.gender || '未入力'}</p>
      <p><strong>職業:</strong> ${payload.occupation || '未入力'}</p>
      <p><strong>趣味:</strong> ${payload.hobbies || '未入力'}</p>
      <p><strong>自己紹介:</strong><br>${(payload.introduction || '未入力').replace(/\n/g, '<br>')}</p>
      <hr>
      <p><strong>LINE User ID:</strong> ${payload.lineUserId || '未入力'}</p>
    `;

    const options = {
      htmlBody: htmlBody
    };

    // 画像ファイルがアップロードされていた場合、メールに添付する
    if (fileBlob) {
      options.attachments = [fileBlob];
    }
    
    MailApp.sendEmail(recipient, subject, "HTMLメール非対応の方向けのメッセージです。", options);
    // --- ▲▲▲ メール通知機能ここまで ▲▲▲ ---


    return ContentService.createTextOutput(
      JSON.stringify({ status: "success" })
    ).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    Logger.log("エラー: " + err.message);
    return ContentService.createTextOutput(
      JSON.stringify({ status: "error", message: err.message })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}
